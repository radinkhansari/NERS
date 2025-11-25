import os
import re
import gradio as gr
import pandas as pd
import oracledb
from typing import Optional, List, Tuple, Dict, Any
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

_pool: Optional[oracledb.ConnectionPool] = None

PROJECT_TABLES = [
    'MAKE',
    'MODEL',
    'TRIM',
    'ENGINE_SPEC',
    'DRIVE_TRAIN',
    'POSITION',
    'BRAND',
    'PART_TYPE',
    'PARTTYPE_BRAND',
    'LISTING',
    'BRAND_ALIAS'
]

PROJECT_VIEWS = [
    'VIEW_NORMALIZEDFITMENT'
]


def get_pool() -> oracledb.ConnectionPool:
    global _pool
    if _pool is None:
        user = os.getenv("ORA_USER")
        password = os.getenv("ORA_PASS")
        dsn = os.getenv("ORA_DB")
        
        if not all([user, password, dsn]):
            raise ValueError(
                "Missing required environment variables: ORA_USER, ORA_PASS, ORA_DB"
            )
        
        try:
            _pool = oracledb.create_pool(
                user=user,
                password=password,
                dsn=dsn,
                min=2,
                max=10,
                increment=1
            )
            logger.info("Oracle connection pool created successfully")
        except Exception as e:
            logger.error(f"Failed to create connection pool: {e}")
            raise
    return _pool


def execute_query(query: str, params: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    pool = get_pool()
    try:
        with pool.acquire() as connection:
            with connection.cursor() as cursor:
                if params:
                    cursor.execute(query, params)
                else:
                    cursor.execute(query)
                
                columns = [desc[0] for desc in cursor.description]
                
                rows = cursor.fetchall()
                
                df = pd.DataFrame(rows, columns=columns)
                
                df.columns = [col.lower() for col in df.columns]
                
                return df
    except Exception as e:
        logger.error(f"Query execution failed: {e}")
        raise


def get_quick_stats() -> Tuple[int, int, int]:
    try:
        listings_df = execute_query("SELECT COUNT(*) as count FROM listing")
        brands_df = execute_query("SELECT COUNT(*) as count FROM brand")
        trims_df = execute_query("SELECT COUNT(*) as count FROM trim")
        
        total_listings = int(listings_df.iloc[0, 0]) if not listings_df.empty else 0
        total_brands = int(brands_df.iloc[0, 0]) if not brands_df.empty else 0
        total_trims = int(trims_df.iloc[0, 0]) if not trims_df.empty else 0
        
        return total_listings, total_brands, total_trims
    except Exception as e:
        logger.error(f"Failed to get quick stats: {e}")
        return 0, 0, 0


def load_makes() -> List[Tuple[str, str]]:
    try:
        df = execute_query("SELECT make_id, make_name FROM make ORDER BY make_name")
        result = [(str(row['make_name']), str(row['make_id'])) for _, row in df.iterrows()]
        logger.info(f"Loaded {len(result)} makes")
        return result
    except Exception as e:
        logger.error(f"Failed to load makes: {e}")
        return []


def load_models(make_id: Optional[str]) -> List[Tuple[str, str]]:
    if not make_id or make_id == "None" or make_id == "":
        return []
    try:
        df = execute_query(
            "SELECT model_id, model_name FROM model WHERE make_id = :make_id ORDER BY model_name",
            {"make_id": int(make_id)}
        )
        result = [(str(row['model_name']), str(row['model_id'])) for _, row in df.iterrows()]
        logger.info(f"Loaded {len(result)} models for make_id={make_id}")
        return result
    except Exception as e:
        logger.error(f"Failed to load models for make_id={make_id}: {e}")
        return []


def load_years(model_id: Optional[str]) -> List[int]:
    if not model_id or model_id == "None":
        return []
    try:
        df = execute_query(
            "SELECT DISTINCT year FROM trim WHERE model_id = :model_id AND year IS NOT NULL ORDER BY year",
            {"model_id": int(model_id)}
        )
        return [int(row['year']) for _, row in df.iterrows() if row['year'] is not None]
    except Exception as e:
        logger.error(f"Failed to load years: {e}")
        return []


def load_trims(model_id: Optional[str], year: Optional[int]) -> List[Tuple[str, str]]:
    if not model_id or model_id == "None":
        return []
    try:
        if year:
            df = execute_query(
                "SELECT trim_id, trim_name FROM trim WHERE model_id = :model_id AND year = :year ORDER BY trim_name",
                {"model_id": int(model_id), "year": int(year)}
            )
        else:
            df = execute_query(
                "SELECT trim_id, trim_name FROM trim WHERE model_id = :model_id ORDER BY trim_name",
                {"model_id": int(model_id)}
            )
        return [(str(row['trim_name']), str(row['trim_id'])) for _, row in df.iterrows()]
    except Exception as e:
        logger.error(f"Failed to load trims: {e}")
        return []


def load_part_types() -> List[Tuple[str, str]]:
    try:
        df = execute_query("SELECT part_type_id, parttype_name FROM part_type ORDER BY parttype_name")
        return [(str(row['parttype_name']), str(row['part_type_id'])) for _, row in df.iterrows()]
    except Exception as e:
        logger.error(f"Failed to load part types: {e}")
        return []


def load_positions() -> List[Tuple[str, str]]:
    try:
        df = execute_query("SELECT position_id, position_code FROM position ORDER BY position_code")
        return [(str(row['position_code']), str(row['position_id'])) for _, row in df.iterrows()]
    except Exception as e:
        logger.error(f"Failed to load positions: {e}")
        return []


def load_drives() -> List[Tuple[str, str]]:
    try:
        df = execute_query("SELECT drive_id, drive_code FROM drive_train ORDER BY drive_code")
        return [(str(row['drive_code']), str(row['drive_id'])) for _, row in df.iterrows()]
    except Exception as e:
        logger.error(f"Failed to load drives: {e}")
        return []


def load_brands() -> List[Tuple[str, str]]:
    try:
        df = execute_query("SELECT brand_id, brand_name FROM brand ORDER BY brand_name")
        return [(str(row['brand_name']), str(row['brand_id'])) for _, row in df.iterrows()]
    except Exception as e:
        logger.error(f"Failed to load brands: {e}")
        return []


def search_fitment(
    make_id: Optional[str],
    model_id: Optional[str],
    year: Optional[int],
    trim_id: Optional[str],
    part_type_id: Optional[str],
    position_id: Optional[str],
    drive_id: Optional[str],
    price_min: Optional[float],
    price_max: Optional[float],
    brand_ids: List[str]
) -> pd.DataFrame:
    try:
        query = """
        SELECT 
            make_name AS "Make",
            model_name AS "Model",
            year AS "Year",
            trim_name AS "Trim",
            brand_name AS "Brand",
            parttype_name AS "Part Type",
            position_code AS "Position",
            drive_code AS "Drive",
            listing_title AS "Listing Title",
            price AS "Price"
        FROM View_NormalizedFitment
        WHERE 1=1
        """
        
        params = {}
        
        if make_id and make_id != "None" and make_id != "":
            query += " AND make_id = :make_id"
            params["make_id"] = int(make_id)
        
        if model_id and model_id != "None" and model_id != "":
            query += " AND model_id = :model_id"
            params["model_id"] = int(model_id)
        
        if year is not None and year != 0:
            query += " AND year = :year"
            params["year"] = int(year)
        
        if trim_id and trim_id != "None" and trim_id != "":
            query += " AND trim_id = :trim_id"
            params["trim_id"] = int(trim_id)
        
        if part_type_id and part_type_id != "None" and part_type_id != "":
            query += " AND part_type_id = :part_type_id"
            params["part_type_id"] = int(part_type_id)
        
        if position_id and position_id != "None" and position_id != "":
            query += " AND position_id = :position_id"
            params["position_id"] = int(position_id)
        
        if drive_id and drive_id != "None" and drive_id != "":
            query += " AND drive_id = :drive_id"
            params["drive_id"] = int(drive_id)
        
        if brand_ids:
            valid_brand_ids = [int(bid) for bid in brand_ids if bid and bid != "None" and bid != ""]
            if valid_brand_ids:
                query += " AND brand_id IN (" + ",".join([f":brand_id_{i}" for i in range(len(valid_brand_ids))]) + ")"
                for i, bid in enumerate(valid_brand_ids):
                    params[f"brand_id_{i}"] = bid

        if price_min is not None and price_min > 0:
            query += " AND (price IS NOT NULL AND price >= :price_min)"
            params["price_min"] = float(price_min)
        
        if price_max is not None and price_max > 0 and price_max < 999999:
            query += " AND (price IS NOT NULL AND price <= :price_max)"
            params["price_max"] = float(price_max)
        
        query += " ORDER BY make_name, model_name, year, brand_name, price"
        query += " FETCH FIRST 1000 ROWS ONLY"
        
        logger.info(f"Executing fitment search with params: {params}")
        logger.info(f"Query: {query}")
        df = execute_query(query, params)
        logger.info(f"Search returned {len(df)} rows")
        
        if df.empty:
            try:
                if make_id:
                    diag_query = "SELECT COUNT(*) as cnt FROM View_NormalizedFitment WHERE make_id = :make_id"
                    diag_params = {"make_id": int(make_id)}
                    if model_id:
                        diag_query += " AND model_id = :model_id"
                        diag_params["model_id"] = int(model_id)
                    diag_df = execute_query(diag_query, diag_params)
                    if not diag_df.empty:
                        cnt = diag_df.iloc[0]['cnt']
                        logger.info(f"Diagnostic: Found {cnt} rows in view for make_id={make_id}, model_id={model_id}")
                        
                        raw_query = """
                        SELECT COUNT(*) as cnt 
                        FROM listing l
                        JOIN trim t ON l.trim_id = t.trim_id
                        WHERE t.make_id = :make_id
                        """
                        raw_params = {"make_id": int(make_id)}
                        if model_id:
                            raw_query += " AND t.model_id = :model_id"
                            raw_params["model_id"] = int(model_id)
                        raw_df = execute_query(raw_query, raw_params)
                        if not raw_df.empty:
                            raw_cnt = raw_df.iloc[0]['cnt']
                            logger.info(f"Diagnostic: Found {raw_cnt} listings with matching trim in raw tables")
                            
                            if raw_cnt == 0:
                                listing_check = "SELECT COUNT(*) as total, COUNT(trim_id) as with_trim FROM listing"
                                listing_df = execute_query(listing_check)
                                if not listing_df.empty:
                                    total_listings = listing_df.iloc[0]['total']
                                    with_trim = listing_df.iloc[0]['with_trim']
                                    logger.info(f"Diagnostic: Total listings={total_listings}, with trim_id={with_trim}")
                                    
                                    trim_check = "SELECT trim_id, trim_name, year FROM trim WHERE make_id = :make_id"
                                    trim_params = {"make_id": int(make_id)}
                                    if model_id:
                                        trim_check += " AND model_id = :model_id"
                                        trim_params["model_id"] = int(model_id)
                                    trim_df = execute_query(trim_check, trim_params)
                                    if not trim_df.empty:
                                        trim_ids = [str(row['trim_id']) for _, row in trim_df.iterrows()]
                                        logger.info(f"Diagnostic: Available trim_ids for this make/model: {trim_ids}")
                                        
                                        if trim_ids:
                                            placeholders = ",".join([f":trim_id_{i}" for i in range(len(trim_ids))])
                                            listing_trim_check = f"SELECT COUNT(*) as cnt FROM listing WHERE trim_id IN ({placeholders})"
                                            listing_trim_params = {f"trim_id_{i}": int(tid) for i, tid in enumerate(trim_ids)}
                                            listing_trim_df = execute_query(listing_trim_check, listing_trim_params)
                                            if not listing_trim_df.empty:
                                                listing_trim_cnt = listing_trim_df.iloc[0]['cnt']
                                                logger.info(f"Diagnostic: Listings using these trim_ids: {listing_trim_cnt}")
                                                
                                                if listing_trim_cnt == 0 and with_trim < total_listings:
                                                    logger.warning(f"Diagnostic: {total_listings - with_trim} listings don't have trim_id set - they won't appear in make/model searches")
            except Exception as diag_error:
                logger.error(f"Diagnostic query failed: {diag_error}")
        
        if df.empty:
            try:
                listing_count_query = "SELECT COUNT(*) as cnt FROM listing"
                listing_count_df = execute_query(listing_count_query)
                if not listing_count_df.empty:
                    total_listings = listing_count_df.iloc[0]['cnt']
                    if total_listings == 0:
                        msg = "⚠️ NO LISTINGS FOUND IN DATABASE"
                        msg += "\n\nThe LISTING table is empty. You need to populate it with data first."
                        msg += "\n\nTo fix this:"
                        msg += "\n1. Run the seed script: sql/web_demo_seed.sql (or your data loading script)"
                        msg += "\n2. Make sure listings include trim_id, drive_id, and position_id values"
                        msg += "\n3. The trim_id links listings to makes/models through the trim table"
                        return pd.DataFrame({"Message": [msg]})
            except Exception as e:
                logger.error(f"Failed to check listing count: {e}")
            
            msg = "No results found matching your criteria."
            if make_id or model_id:
                msg += "\n\n⚠️ IMPORTANT: Listings must have a trim_id set to appear when filtering by Make/Model."
                msg += "\n\nThis is because the view joins through the trim table to get make/model information."
                msg += "\nIf listings don't have trim_id values, they won't match make/model filters."
                msg += "\n\nTo fix this:"
                msg += "\n1. Check the Schema Peek tab → LISTING table to see if trim_id values are set"
                msg += "\n2. Update listings to include trim_id values that link to the correct trim"
                msg += "\n3. Or search without Make/Model filters to see all listings"
            else:
                msg += "\n\nTry removing some filters or checking if data exists in the database."
            return pd.DataFrame({"Message": [msg]})
        
        return df
    except Exception as e:
        logger.error(f"Fitment search failed: {e}")
        return pd.DataFrame({"Error": [str(e)]})


def compute_coverage(
    make_id: Optional[str],
    model_id: Optional[str],
    year: Optional[int],
    part_type_id: Optional[str]
) -> pd.DataFrame:
    try:
        query = """
        SELECT 
            brand_name AS "Brand Name",
            parttype_name AS "Part Type",
            COUNT(*) AS "Listing Count",
            MIN(price) AS "Cheapest Price"
        FROM View_NormalizedFitment
        WHERE 1=1
        """
        
        params = {}
        
        if make_id and make_id != "None" and make_id != "":
            query += " AND make_id = :make_id"
            params["make_id"] = int(make_id)
        
        if model_id and model_id != "None" and model_id != "":
            query += " AND model_id = :model_id"
            params["model_id"] = int(model_id)
        
        if year is not None and year != 0:
            query += " AND year = :year"
            params["year"] = int(year)
        
        if part_type_id and part_type_id != "None" and part_type_id != "":
            query += " AND part_type_id = :part_type_id"
            params["part_type_id"] = int(part_type_id)
        
        query += " GROUP BY brand_name, parttype_name"
        query += " ORDER BY brand_name, parttype_name"
        
        df = execute_query(query, params)
        
        if df.empty:
            return pd.DataFrame({"Message": ["No coverage data found matching your criteria."]})
        
        return df
    except Exception as e:
        logger.error(f"Coverage computation failed: {e}")
        return pd.DataFrame({"Error": [str(e)]})


def load_alias_collisions() -> pd.DataFrame:
    try:
        query = """
        SELECT 
            alias_text AS "Alias Text",
            LISTAGG(DISTINCT canonical_value, ', ') WITHIN GROUP (ORDER BY canonical_value) AS "Canonical Values",
            COUNT(DISTINCT canonical_value) AS "Collision Count"
        FROM brand_alias
        WHERE canonical_value IS NOT NULL
        GROUP BY alias_text
        HAVING COUNT(DISTINCT canonical_value) > 1
        ORDER BY "Collision Count" DESC, alias_text
        """
        
        df = execute_query(query)
        if df.empty:
            return pd.DataFrame({"Message": ["No alias collisions found."]})
        return df
    except Exception as e:
        logger.error(f"Failed to load alias collisions: {e}")
        error_msg = str(e)
        if "table or view does not exist" in error_msg.lower():
            return pd.DataFrame({
                "Message": [
                    "brand_alias table not found.",
                    "Please run extend_schema.sql to create the brand_alias table."
                ]
            })
        return pd.DataFrame({"Error": [error_msg]})


def load_missing_mpn() -> pd.DataFrame:
    try:
        query = """
        SELECT 
            listing_id AS "Listing ID",
            listing_title AS "Listing Title",
            brand_id AS "Brand ID",
            part_type_id AS "Part Type ID"
        FROM listing
        WHERE mpn IS NULL
        ORDER BY listing_id
        FETCH FIRST 500 ROWS ONLY
        """
        df = execute_query(query)
        if df.empty:
            return pd.DataFrame({"Message": ["No listings with missing MPN found."]})
        return df
    except Exception as e:
        logger.error(f"Failed to load missing MPN: {e}")
        return pd.DataFrame({"Error": [str(e)]})


def load_oem_mismatches() -> pd.DataFrame:
    try:
        query = """
        SELECT 
            l.listing_id AS "Listing ID",
            l.listing_title AS "Listing Title",
            b.brand_name AS "Brand Name",
            CASE 
                WHEN UPPER(l.listing_title) LIKE '%OEM%' AND b.brand_name NOT LIKE '%OEM%' 
                THEN 'Title suggests OEM but brand does not match'
                ELSE 'Potential OEM mismatch'
            END AS "Reason"
        FROM listing l
        JOIN brand b ON l.brand_id = b.brand_id
        WHERE UPPER(l.listing_title) LIKE '%OEM%'
        ORDER BY l.listing_id
        FETCH FIRST 500 ROWS ONLY
        """
        df = execute_query(query)
        if df.empty:
            return pd.DataFrame({"Message": ["No OEM descriptor mismatches found."]})
        return df
    except Exception as e:
        logger.error(f"Failed to load OEM mismatches: {e}")
        return pd.DataFrame({"Error": [str(e)]})


def load_tables() -> List[str]:
    try:
        tables_df = execute_query("SELECT table_name FROM user_tables ORDER BY table_name")
        views_df = execute_query("SELECT view_name AS table_name FROM user_views ORDER BY view_name")
        
        all_objects = pd.concat([tables_df, views_df], ignore_index=True)
        
        project_objects = set(t.upper() for t in PROJECT_TABLES + PROJECT_VIEWS)
        
        filtered = [
            str(row['table_name']) 
            for _, row in all_objects.iterrows() 
            if str(row['table_name']).upper() in project_objects
        ]
        
        return sorted(filtered)
    except Exception as e:
        logger.error(f"Failed to load tables: {e}")
        return []


def preview_table(table_name: str) -> pd.DataFrame:
    if not table_name or table_name == "None":
        return pd.DataFrame({"Message": ["Please select a table or view"]})
    
    try:
        tables = load_tables()
        if table_name not in tables:
            return pd.DataFrame({"Error": [f"Table/view '{table_name}' not found in project schema"]})
        
        query = f'SELECT * FROM "{table_name}" FETCH FIRST 50 ROWS ONLY'
        df = execute_query(query)
        
        if df.empty:
            return pd.DataFrame({"Message": [f"Table/view '{table_name}' is empty or has no rows."]})
        
        return df
    except Exception as e:
        logger.error(f"Failed to preview table/view: {e}")
        return pd.DataFrame({"Error": [str(e)]})


def lookup_aliases_from_text(input_text: str) -> pd.DataFrame:
    """
    Parse input text by spaces, and find words that exist in BRAND_ALIAS
    either as alias_text or canonical_value. Returns matching alias_text rows.
    """
    try:
        if not input_text or not input_text.strip():
            return pd.DataFrame({"Message": ["Please enter some text to analyze."]})

        # Split by spaces as requested
        raw_tokens = input_text.strip().split()

        # Normalize to upper-case to match case-insensitively
        tokens = {t.strip().upper() for t in raw_tokens if t.strip()}
        if not tokens:
            return pd.DataFrame({"Message": ["No valid tokens found in the input text."]})

        # Build IN list for Oracle safely
        placeholders = ", ".join([f":word_{i}" for i in range(len(tokens))])
        params = {f"word_{i}": word for i, word in enumerate(tokens)}

        query = f"""
        SELECT DISTINCT
            alias_text       AS "Alias Text",
            canonical_value  AS "Canonical Value"
        FROM brand_alias
        WHERE UPPER(alias_text) IN ({placeholders})
           OR UPPER(canonical_value) IN ({placeholders})
        ORDER BY "Alias Text", "Canonical Value"
        """

        df = execute_query(query, params)

        if df.empty:
            return pd.DataFrame({"Message": ["No aliases found in BRAND_ALIAS for any of the words in your text."]})

        return df

    except Exception as e:
        logger.error(f"Alias lookup from text failed: {e}")
        return pd.DataFrame({"Error": [str(e)]})


def create_app():    
    try:
        get_pool()
        logger.info("Application initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize application: {e}")
        with gr.Blocks(title="Auto Parts Fitment Explorer - Connection Error") as app:
            gr.Markdown("# Auto Parts Fitment Explorer")
            gr.Markdown(f"## Connection Error\n\nFailed to connect to Oracle database: {str(e)}\n\nPlease check your environment variables: ORA_USER, ORA_PASS, ORA_DB")
        return app
    
    try:
        total_listings, total_brands, total_trims = get_quick_stats()
    except Exception as e:
        logger.error(f"Failed to get initial stats: {e}")
        total_listings, total_brands, total_trims = 0, 0, 0
    
    makes = load_makes()
    part_types = load_part_types()
    positions = load_positions()
    drives = load_drives()
    brands = load_brands()
    
    with gr.Blocks(title="Auto Parts Fitment Explorer") as app:
        gr.Markdown("# Auto Parts Fitment Explorer")
        gr.Markdown("### Search fitment, compare brands, and inspect data quality (Oracle-backed).")
        
        with gr.Row():
            total_listings_widget = gr.Number(
                value=total_listings,
                label="Total Listings",
                interactive=False,
                precision=0
            )
            total_brands_widget = gr.Number(
                value=total_brands,
                label="Total Brands",
                interactive=False,
                precision=0
            )
            total_trims_widget = gr.Number(
                value=total_trims,
                label="Total Trims",
                interactive=False,
                precision=0
            )
        
        with gr.Tabs():
            # ---------------------- Fitment Search Tab ----------------------
            with gr.Tab("Fitment Search"):
                with gr.Row():
                    with gr.Column(scale=1):
                        make_dropdown = gr.Dropdown(
                            choices=makes,
                            label="Make",
                            value=None,
                            interactive=True
                        )
                        
                        model_dropdown = gr.Dropdown(
                            choices=[],
                            label="Model",
                            value=None,
                            interactive=True
                        )
                        
                        year_input = gr.Number(
                            label="Year (Optional)",
                            value=None,
                            precision=0,
                            interactive=True
                        )
                        
                        trim_dropdown = gr.Dropdown(
                            choices=[],
                            label="Trim (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        part_type_dropdown = gr.Dropdown(
                            choices=part_types,
                            label="Part Type (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        position_dropdown = gr.Dropdown(
                            choices=positions,
                            label="Position (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        drive_dropdown = gr.Dropdown(
                            choices=drives,
                            label="Drive (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        with gr.Row():
                            price_min_input = gr.Number(
                                label="Price Min (Optional, leave empty for no minimum)",
                                value=None,
                                interactive=True
                            )
                            price_max_input = gr.Number(
                                label="Price Max (Optional, leave empty for no maximum)",
                                value=None,
                                interactive=True
                            )
                        
                        brand_checkbox = gr.CheckboxGroup(
                            choices=brands,
                            label="Brands (Multi-select)",
                            interactive=True
                        )
                        
                        with gr.Row():
                            search_button = gr.Button("Search Fitment", variant="primary")
                            clear_filters_button = gr.Button("Clear Filters", variant="secondary")
                            clear_search_button = gr.Button("Clear Results", variant="secondary")
                    
                    with gr.Column(scale=2):
                        fitment_results = gr.Dataframe(
                            label="Fitment Results",
                            interactive=False,
                            wrap=True
                        )
                
                def update_models_and_trim(make_id):
                    if not make_id or make_id == "None" or make_id == "":
                        return gr.update(choices=[], value=None), gr.update(choices=[], value=None)
                    models = load_models(make_id)
                    return gr.update(choices=models, value=None), gr.update()
                
                make_dropdown.change(
                    fn=update_models_and_trim,
                    inputs=[make_dropdown],
                    outputs=[model_dropdown, trim_dropdown]
                )
                
                def update_trims(model_id, year):
                    if not model_id or model_id == "None" or model_id == "":
                        return gr.update(choices=[], value=None)
                    trims = load_trims(model_id, int(year) if year else None)
                    return gr.update(choices=trims, value=None)
                
                model_dropdown.change(
                    fn=lambda m: update_trims(m, None),
                    inputs=[model_dropdown],
                    outputs=[trim_dropdown]
                )
                
                def update_trims_from_year(model_id, year):
                    if not model_id or model_id == "None" or model_id == "":
                        return gr.update(choices=[], value=None)
                    return update_trims(model_id, int(year) if year else None)
                
                year_input.change(
                    fn=update_trims_from_year,
                    inputs=[model_dropdown, year_input],
                    outputs=[trim_dropdown]
                )
                
                def clear_search_results():
                    return pd.DataFrame({"Message": ["Results cleared. Adjust filters and click 'Search Fitment' to run a new query."]})
                
                def clear_all_filters():
                    return (
                        gr.update(value=None),  # make_dropdown
                        gr.update(choices=[], value=None),  # model_dropdown
                        gr.update(value=None),  # year_input
                        gr.update(choices=[], value=None),  # trim_dropdown
                        gr.update(value=None),  # part_type_dropdown
                        gr.update(value=None),  # position_dropdown
                        gr.update(value=None),  # drive_dropdown
                        gr.update(value=None),  # price_min_input
                        gr.update(value=None),  # price_max_input
                        gr.update(value=[]),  # brand_checkbox
                        pd.DataFrame({"Message": ["All filters cleared. Select new filters and click 'Search Fitment'."]})  # results
                    )
                
                search_button.click(
                    fn=search_fitment,
                    inputs=[
                        make_dropdown,
                        model_dropdown,
                        year_input,
                        trim_dropdown,
                        part_type_dropdown,
                        position_dropdown,
                        drive_dropdown,
                        price_min_input,
                        price_max_input,
                        brand_checkbox
                    ],
                    outputs=[fitment_results]
                )
                
                clear_filters_button.click(
                    fn=clear_all_filters,
                    outputs=[
                        make_dropdown,
                        model_dropdown,
                        year_input,
                        trim_dropdown,
                        part_type_dropdown,
                        position_dropdown,
                        drive_dropdown,
                        price_min_input,
                        price_max_input,
                        brand_checkbox,
                        fitment_results
                    ]
                )
                
                clear_search_button.click(
                    fn=clear_search_results,
                    outputs=[fitment_results]
                )
            
            # ---------------------- Brand & Part Coverage Tab ----------------------
            with gr.Tab("Brand & Part Coverage"):
                with gr.Row():
                    with gr.Column(scale=1):
                        coverage_make_dropdown = gr.Dropdown(
                            choices=makes,
                            label="Make (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        coverage_model_dropdown = gr.Dropdown(
                            choices=[],
                            label="Model (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        coverage_year_input = gr.Number(
                            label="Year (Optional)",
                            value=None,
                            precision=0,
                            interactive=True
                        )
                        
                        clear_coverage_button = gr.Button("Clear Results", variant="secondary")
                        
                        coverage_part_type_dropdown = gr.Dropdown(
                            choices=part_types,
                            label="Part Type (Optional)",
                            value=None,
                            interactive=True
                        )
                        
                        coverage_button = gr.Button("Compute Coverage", variant="primary")
                    
                    with gr.Column(scale=2):
                        coverage_results = gr.Dataframe(
                            label="Brand & Part Coverage Results",
                            interactive=False,
                            wrap=True
                        )
                
                def update_coverage_models(make_id):
                    if not make_id or make_id == "None" or make_id == "":
                        return gr.update(choices=[], value=None)
                    models = load_models(make_id)
                    return gr.update(choices=models, value=None)
                
                coverage_make_dropdown.change(
                    fn=update_coverage_models,
                    inputs=[coverage_make_dropdown],
                    outputs=[coverage_model_dropdown]
                )
                
                def clear_coverage():
                    return pd.DataFrame({"Message": ["Results cleared. Click 'Compute Coverage' to run a new query."]})
                
                coverage_button.click(
                    fn=compute_coverage,
                    inputs=[
                        coverage_make_dropdown,
                        coverage_model_dropdown,
                        coverage_year_input,
                        coverage_part_type_dropdown
                    ],
                    outputs=[coverage_results]
                )
                
                clear_coverage_button.click(
                    fn=clear_coverage,
                    outputs=[coverage_results]
                )
            
            # ---------------------- Data Quality Tab ----------------------
            with gr.Tab("Data Quality"):
                def clear_dataframe():
                    return pd.DataFrame({"Message": ["Results cleared. Click the button above to load data again."]})
                
                with gr.Accordion("Alias Collisions", open=True):
                    with gr.Row():
                        alias_button = gr.Button("Load Alias Collisions", variant="primary")
                        clear_alias_button = gr.Button("Clear Results", variant="secondary")
                    alias_results = gr.Dataframe(
                        label="Alias Collisions",
                        interactive=False,
                        wrap=True
                    )
                    alias_button.click(
                        fn=load_alias_collisions,
                        outputs=[alias_results]
                    )
                    clear_alias_button.click(
                        fn=clear_dataframe,
                        outputs=[alias_results]
                    )
                
                with gr.Accordion("Listings with Missing MPN", open=True):
                    with gr.Row():
                        mpn_button = gr.Button("Load Listings with Missing MPN", variant="primary")
                        clear_mpn_button = gr.Button("Clear Results", variant="secondary")
                    mpn_results = gr.Dataframe(
                        label="Listings with Missing MPN",
                        interactive=False,
                        wrap=True
                    )
                    mpn_button.click(
                        fn=load_missing_mpn,
                        outputs=[mpn_results]
                    )
                    clear_mpn_button.click(
                        fn=clear_dataframe,
                        outputs=[mpn_results]
                    )
                
                with gr.Accordion("OEM Descriptor vs Brand Mismatch", open=True):
                    with gr.Row():
                        oem_button = gr.Button("Load OEM Descriptor Mismatches", variant="primary")
                        clear_oem_button = gr.Button("Clear Results", variant="secondary")
                    oem_results = gr.Dataframe(
                        label="OEM Descriptor Mismatches",
                        interactive=False,
                        wrap=True
                    )
                    oem_button.click(
                        fn=load_oem_mismatches,
                        outputs=[oem_results]
                    )
                    clear_oem_button.click(
                        fn=clear_dataframe,
                        outputs=[oem_results]
                    )
            
            # ---------------------- Schema Peek Tab ----------------------
            with gr.Tab("Schema Peek"):
                with gr.Row():
                    with gr.Column(scale=1):
                        initial_tables = load_tables()
                        table_dropdown = gr.Dropdown(
                            choices=initial_tables,
                            label="Table",
                            value=None,
                            interactive=True
                        )
                        with gr.Row():
                            preview_button = gr.Button("Preview Rows", variant="primary")
                            clear_preview_button = gr.Button("Clear Preview", variant="secondary")
                        refresh_tables_button = gr.Button("Refresh Table List", variant="secondary")
                    
                    with gr.Column(scale=2):
                        table_preview = gr.Dataframe(
                            label="Table Preview (First 50 Rows)",
                            interactive=False,
                            wrap=True
                        )
                
                def load_tables_for_dropdown():
                    tables = load_tables()
                    return gr.update(choices=tables)
                
                refresh_tables_button.click(
                    fn=load_tables_for_dropdown,
                    outputs=[table_dropdown]
                )
                
                def clear_table_preview():
                    return pd.DataFrame({"Message": ["Preview cleared. Select a table and click 'Preview Rows' to load data."]})
                
                preview_button.click(
                    fn=preview_table,
                    inputs=[table_dropdown],
                    outputs=[table_preview]
                )
                
                clear_preview_button.click(
                    fn=clear_table_preview,
                    outputs=[table_preview]
                )

            # ---------------------- Alias Text Lookup Tab (NEW) ----------------------
            with gr.Tab("Alias Text Lookup"):
                gr.Markdown("### Paste text and detect brand aliases from BRAND_ALIAS (by alias_text or canonical_value).")

                with gr.Row():
                    with gr.Column(scale=1):
                        alias_input_box = gr.Textbox(
                            label="Input Text",
                            placeholder="Paste listing title, description, or any text here...",
                            lines=4,
                        )
                        alias_lookup_button = gr.Button("Detect Aliases", variant="primary")
                        alias_clear_button = gr.Button("Clear Results", variant="secondary")

                    with gr.Column(scale=2):
                        alias_lookup_results = gr.Dataframe(
                            label="Detected Brand Aliases",
                            interactive=False,
                            wrap=True
                        )

                def clear_alias_lookup_results():
                    return pd.DataFrame({"Message": ["Results cleared. Paste new text and click 'Detect Aliases'."]})

                alias_lookup_button.click(
                    fn=lookup_aliases_from_text,
                    inputs=[alias_input_box],
                    outputs=[alias_lookup_results]
                )

                alias_clear_button.click(
                    fn=clear_alias_lookup_results,
                    outputs=[alias_lookup_results]
                )
    
    return app


if __name__ == "__main__":
    app = create_app()
    app.launch(server_name="0.0.0.0", server_port=7860, share=False)