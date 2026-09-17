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
=======================================================================================
Gold Layer | Create Dimension: gold.dim_customers
======================================================================================= 
In Gold Layer we are using VIEWS, So we din't have Stored Procedures Or Loading Process
only Data Transformations Focusing on:
	- Data Integration
	- Data Aggregation
	- Business Logic & Rules

Our Scope: Star Schema
Data Selection: From Silver Layer
*/

SELECT *
FROM silver.crm_cust_info;

--[1] Select the Columns that we need to be presented in the Gold Layer | Don't grap the METADATA Inf --> belongs to silver
--[2] Give the table an Alias --> As later we will join it with other tables

SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date
FROM silver.crm_cust_info AS ci;

--[3] Jump to the other table - Get the BirthDate inf from erp_cust_az12
--    Start with the master table - Avoid the INNER JOIN | As the the other source might not have all the customers!
--[4] Jump to the other table - Get the Location inf from erp_loc_a101

SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid	  

-- Now we have collected all the customer's information that we have in the two systems
-- TIP: After joining tables, check if any duplicates were introduces by the join logic 
-- Check

SELECT 
	cst_id,
	COUNT(*)
FROM(
	SELECT
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info      AS ci
	LEFT JOIN silver.erp_cust_az12 AS ca
	ON        ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101  AS la 
	ON	      ci.cst_key = la.cid
) AS t
GROUP BY cst_id
HAVING COUNT(*) > 1;   -- OutPut: Nothing --> No Dupes

/*
But we hve integration issue - We have two information about the gender 
1 from the crm & one from erp
Solution: Data Integration 
	- Make a new query
	- Remove all the columns exept the two with the issue and use DISTINCT
*/

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid
ORDER BY 1, 2;

/*
OutPUT:
	- Matching values
	- Different inf in the same row !
	  Ask the expert, What is the master here for these values? crm or erp?
	  Considering that the Master Source of customer Data is CRM
		
	- Data from a table and n/a from the other 
	- NULL !!!!! | HOW & WHY?
	  NULLs often come from joined tables!
	  NULLs will appear if SQL finds no match
 */

 -- Build the logic:

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr  -- CRM is the Master
	     ELSE COALESCE(ca.gen, 'N/A')
	END AS new_gendr
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid
ORDER BY 1, 2;

-- Final Query of this table

SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
	     ELSE COALESCE(ca.gen, 'N/A')
	END AS new_gendr,
	ci.cst_create_date,
	ca.bdate,
	la.cntry
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid	 

-- [5] Rename columns to friendly, meaningful names
/*
General Principles
	- Naming Conventions: Use snake_case, with lowercase letters and underscores (_) to separate words.
	- Language : Use English for all names.
	- Avoid Reserved Words: Do not use SQL reserved words as object names. */

SELECT
	ci.cst_id			  AS customer_id,
	ci.cst_key            AS customer_number,
	ci.cst_firstname      AS first_name,
	ci.cst_lastname       AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
	     ELSE COALESCE(ca.gen, 'N/A')
	END                   AS gender,
	ci.cst_create_date    AS create_date,
	ca.bdate			  AS birthdate,
	la.cntry              AS country
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid	

-- [6] Sort the columns into logical groups to improve readability.

SELECT
	ci.cst_id			  AS customer_id,
	ci.cst_key            AS customer_number,
	ci.cst_firstname      AS first_name,
	ci.cst_lastname       AS last_name,
	la.cntry              AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
	     ELSE COALESCE(ca.gen, 'N/A')
	END                   AS gender,
	ca.bdate			  AS birthdate,
	ci.cst_create_date    AS create_date	
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid

/*
This table Dimension Or Fact?
Dimension | As it holds a descriptive info about an object!! --> Call it a dimension Customers
When we create a dimension we need inddedly a PK!
	- From the source system itself
	- If NOT:
	  We have to generate a PK in the DataWarehouse --> Called Surrogate Key
Surrogate Key:
	System-generated unique identifier assigned to each record in a table 
	Not a business key, has no meaning
	Only used in order to connect our data model!
	We don't have to depend always on the source system

[7] How to generate Surrogate Key:
	- DDL-Based Generation
	- Query-Based using Window Function (ROW_NUMBER)
In this project --> Window Function */

SELECT
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
	ci.cst_id			  AS customer_id,
	ci.cst_key            AS customer_number,
	ci.cst_firstname      AS first_name,
	ci.cst_lastname       AS last_name,
	la.cntry              AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
	     ELSE COALESCE(ca.gen, 'N/A')
	END                   AS gender,
	ca.bdate			  AS birthdate,
	ci.cst_create_date    AS create_date	
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid

--[8] Create an object | for Gold Layer it will be a virtual one --> VIEW

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
   DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
	ci.cst_id			  AS customer_id,
	ci.cst_key            AS customer_number,
	ci.cst_firstname      AS first_name,
	ci.cst_lastname       AS last_name,
	la.cntry              AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
	     ELSE COALESCE(ca.gen, 'N/A')
	END                   AS gender,
	ca.bdate			  AS birthdate,
	ci.cst_create_date    AS create_date	
FROM silver.crm_cust_info      AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la 
ON	      ci.cst_key = la.cid;

-- Quality Check of the Gold View
SELECT *
FROM gold.dim_customers;

/*
=======================================================================================
Gold Layer | Create Dimension: gold.dim_customers
=======================================================================================
We will start with the CRM info
Joining with the ERP info 
In order to get the whole information about products 

CRM --> Contains the historical and current info about the products
It depends on the requirement! Whether You need the historical or not!!

--[1] Select the Columns that we need to be presented in the Gold Layer | Don't grap the METADATA Inf --> belongs to silver
	  We Will go and stay with only the current info!!
	  So, using the prd_end_date in order to select only the current data 
	  if the prd_end_date  is NULL then it is current info of the product
--[2] Give the table an Alias --> As later we will join it with other tables
*/
SELECT
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt
  FROM      silver.crm_prd_info    AS pn
  WHERE prd_end_dt IS NULL;  -- Filter out all historical data 

--[3] Grap category inf from the other table silver.erp_px_cat_g1v2 --> ERP
SELECT
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
  FROM      silver.crm_prd_info    AS pn
  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON        pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL;  -- Filter out all historical data 

-- Now we have collected all the products's information that we have in the two systems
-- TIP: After joining tables, check if any duplicates were introduces by the join logic 
-- Check Uniqueness

SELECT
	prd_key,
	COUNT(*)
FROM(
	SELECT
		pn.prd_id,
		pn.cat_id,
		pn.prd_key,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	  FROM      silver.crm_prd_info    AS pn
	  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
	  ON        pn.cat_id = pc.id
	  WHERE pn.prd_end_dt IS NULL
) AS t
GROUP BY prd_key
HAVING COUNT(*) > 1;  -- OutPut: Nothing --> No Dupes

/*
Till Now
	- No historical Data 
	- No Dupes
	- No Integration Issues
*/

-- [4] Sort the columns into logical groups to improve readability | Group Up the relevant information together

SELECT
	pn.prd_id,
	pn.prd_key,
	pn.prd_nm,
	pn.cat_id,
	pc.cat,
	pc.subcat,
	pc.maintenance,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt
  FROM      silver.crm_prd_info    AS pn
  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON        pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL;  -- Filter out all historical data 

-- [5] Rename columns to friendly, meaningful names

SELECT
	pn.prd_id		AS product_id,
	pn.prd_key		AS product_number,
	pn.prd_nm		AS product_name,
	pn.cat_id		AS category_id,
	pc.cat			AS category,
	pc.subcat		AS subcategory,
	pc.maintenance  AS maintenance,
	pn.prd_cost		AS cost,
	pn.prd_line     AS product_line,
	pn.prd_start_dt AS start_date
  FROM      silver.crm_prd_info    AS pn
  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON        pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL;  -- Filter out all historical data

/*
This table Dimension Or Fact?
Dimension | As it holds a descriptive info about an object!! --> Call it a dimension products
When we create a dimension we need indeedly a PK!
*/

-- [6] Generate Surrogate Key

SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id		AS product_id,
	pn.prd_key		AS product_number,
	pn.prd_nm		AS product_name,
	pn.cat_id		AS category_id,
	pc.cat			AS category,
	pc.subcat		AS subcategory,
	pc.maintenance  AS maintenance,
	pn.prd_cost		AS cost,
	pn.prd_line     AS product_line,
	pn.prd_start_dt AS start_date
  FROM      silver.crm_prd_info    AS pn
  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON        pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL;  -- Filter out all historical data

--[7] Create an object | for Gold Layer it will be a virtual one --> VIEW

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id		AS product_id,
	pn.prd_key		AS product_number,
	pn.prd_nm		AS product_name,
	pn.cat_id		AS category_id,
	pc.cat			AS category,
	pc.subcat		AS subcategory,
	pc.maintenance  AS maintenance,
	pn.prd_cost		AS cost,
	pn.prd_line     AS product_line,
	pn.prd_start_dt AS start_date
  FROM      silver.crm_prd_info    AS pn
  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON        pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL;  -- Filter out all historical data


SELECT *
FROM gold.dim_products;

/*
=======================================================================================
Gold Layer | Create Fact sales: gold.fact_sales
=======================================================================================
*/


SELECT 
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details

-- Only One table, no need for integration.. etc
/*
This table Dimension Or Fact?
Fact | As it holds a transactions, events, a lot of keys, measures and dates about an object!! --> Call it a fact sales
When we create a fact we are connecting multiple dimensions &
We have to present in this fact the surrogte keys that come from the dimensions

Building Fact
Use the dimension's surrogate key instead of ID's 
to easily connect facts with dimensions!
By joining the two dimensions to get their surrogate keys!
*/

SELECT 
    sd.sls_ord_num,
	pr.product_key,
	cu.customer_id,
	sd.sls_order_dt,
	sd.sls_ship_dt,
	sd.sls_due_dt,
	sd.sls_sales,
	sd.sls_quantity,
	sd.sls_price
FROM      silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products        AS pr
ON        sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers       AS cu
ON        sd.sls_cust_id = cu.customer_id


-- [2] Rename columns to friendly, meaningful names

SELECT 
    sd.sls_ord_num  AS order_number,
	pr.product_key  AS product_key,
	cu.customer_key AS customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt  AS shipping_date,
	sd.sls_due_dt   AS due_date,
	sd.sls_sales	AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price	AS price
FROM      silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products        AS pr
ON        sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers       AS cu
ON        sd.sls_cust_id = cu.customer_id

-- [3] Sort the columns into logical groups to improve readability | Group Up the relevant information together
-- [4] Create an object | for Gold Layer it will be a virtual one --> VIEW

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
	sd.sls_sales	AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price	AS price
FROM      silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products        AS pr
ON        sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers       AS cu
ON        sd.sls_cust_id = cu.customer_id;


-- Quality Check of the Gold View
SELECT * 
FROM gold.fact_sales;

-- Fact Check
-- Check if all dimension tables can successfully join to the fact table
-- Try to connect the whole data model in order to find any issues 
-- Foreign Key Integrity (Dimensions) 

SELECT * 
FROM      gold.fact_sales    AS f
LEFT JOIN gold.dim_customers AS c
ON        f.customer_key = c.customer_key
LEFT JOIN gold.dim_products AS p
ON        f.product_key = p.product_key
WHERE c.customer_key IS NULL 
OR    p.product_key  IS NULL 

/*
=======================================================================================
Gold Layer | Build the Star Schema Model
=======================================================================================

[1] Draw all tables (dims & fact) 
    Write all columns
	Add PKs
	Add FKs
[2] Describe the relationship between these tables
    Very important step for reporting and analytics
	In order to understand how to use the dat model

Relationship
	In a Star Schema, the relationship between fact and dimensions is 1:N --> One to Many.
[3] Choose the relationship --> 1 Mandatory to Many Optional
	One (Mandatory) Means that the customer MUST exist in the dimension table 
	Many (Optional)
		1. Customers who haven't placed any orders yet
		2. Customers who have placed only one order
		3. Customers who have placed many orders 
You can add texts to explain any complec concept or calculation in the model

=======================================================================================
Gold Layer | Build Data Catalog
=======================================================================================
It is a document that describes everything about your Data Product | Data Model
Create a direct .md file at Github --> data_catalog.md 
	- Describe these tables
	- Ex 
	  1. gold.dim_customers
		 Purpose: Stores customer details enriched with demographic and geographic data 
		 columns:
		 Add a very short describtion for each colummn!
		 Best practice is to give examples for each column!  .. So on for each table | File will be attached

=======================================================================================
Gold Layer | Extend Data Flow
=======================================================================================

=======================================================================================
Gold Layer | Commit Code in Git Repo
=======================================================================================
*/
