/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.

===============================================================================
Gold Layer 
===============================================================================
Before create the Gold Layer
Analysing:
---------
    Explore & Understand the Business Objects
    that are hidden inside our source systems
Coding:
------
    Data Integration 
    Three Steps:
        - Build the Business Object!
        - Choose Type dimension VS Fact | Flat Table!
        - Rename to Friendly Names
          rename all the columns into a friendly names & easy to understand

Validating:
----------
    Data Integration Checks
Docs & Version:
--------------
    Data Documenting Versioning in GIT
        - Data Model
        - Data Catalog
        - Data Flow Diagram

===============================================================================
Theory | What is Data Modeling?
-------------------------------------------------------------------------------
The Process of taking raw data and organize, structure it in meaningful way
    - Conceptual Data Model  | Big Picture
      Focusing only on the Entity! | No Details 
      What are he Entities that we have and the relationships between them
    - Logical Data Model  | Blue Print
      Specifying what are different columns that we can find in each Entity
      Still draw the the relationships between them 
      Make it clear what are the PKs & So on 
      No worry about how to store those tables in the Database
    - Physical Data Model  | Implementation
      Where Everything Getting Ready Before Creating it in the DataBase
      Add all the technical details | Data Type for each column | Length of Each Data Type..

Hint: Draw only the Conceptual & the Logical
In this project we will draw the Logical Data Model  for the Gold Layer

We need special data model that is 
    - Optimized for Reporting
    - Flexible 
    - Easy to Understand
===============================================================================
Theory | Star Schema VS Snowflake Schema
-------------------------------------------------------------------------------
Star Schema 
    - Central Fact Table surronded by Dimensions
    - Fact Table contains transactions, events
    - Dimensions contain Descriptive Information
    - Forming a star shape  
    - Simple & Easy
    - Issue: Big Dimensions! 
Snowflake Schema 
    - Central Fact Table surronded by Dimensions
    - Dimesions -- Breaking --> Smaller Sub_Dimesions
    - Extending the Dimesions Looks like a Snow_flake
    - More Complex
    - Large DataSets
In this project we will Star Schema
===============================================================================
Theory | Dimensions VS Facts
-------------------------------------------------------------------------------
Dimension
    - Descriptive Information
      that give context to your data
    - Answers to
        Who?
        What?
        Where?
Fact
    - Quantitative information
      that represents events
    - Answers to
        How Much?
        How Many?

===============================================================================
Gold Layer | Explore the Business Object 
-------------------------------------------------------------------------------
In order to build a new data model, wehave to undersatnd the original data model!
What are the main business objects that we have?
How things are related to each other?
    - Start by giving labels to all these tables -- Draw.io
    - Build those objects step by step
- Start with customers | crm
================================================================================
Gold Layer | Create Dimension: gold.dim_customers
================================================================================ */
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Surrogate key
    ci.cst_id                          AS customer_id,
    ci.cst_key                         AS customer_number,
    ci.cst_firstname                   AS first_name,
    ci.cst_lastname                    AS last_name,
    la.cntry                           AS country,
    ci.cst_marital_status              AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(ca.gen, 'n/a')  			   -- Fallback to ERP data
    END                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Filter out all historical data
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
