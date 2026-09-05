/*
Before create the Bronze Layer
Analysing:
---------
    Interview Source System Experts
    In Order to understand the nature of source system that You're connecting 
    to thae datawarehouse
Coding:
------
    Data Ingestion
    To find a way on how to load the data from the data source
    into the datawarehouse
Validating:
----------
    Data Completeness & Schema Checks
    It is very important in the Bronze Layer to check Data Completeness
    We have to compare the number of records between the data sources and 
    the Bronze Layer to make sure that we are not losing any data in between
    Schema Checks
    To make sure that everything is in the right place
Docs & Version:
--------------
    Data Documenting Versioning in GIT

===============================================================================
Analyse Source System
-------------------------------------------------------------------------------
Source System interview --> ScreenShot

===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Data Defenition Language defines the structure of database tables
You have to understand the Metadata |Strucure | Schema of the incoming data
    - Consult the technical experts of the source system to understand its Metadata
    - Or Data Profiling
      Explore the data to identify column names & data types
Create SQL DDL scripts for ALLM CSV Files.

Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/
-- To check if the table exists ?
-- Use T-SQL 

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL --> 'U' Stands for User Defined Table
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (     -- Following the naming convention
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);
GO

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);
GO

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid    NVARCHAR(50),
    cntry  NVARCHAR(50)
);
GO

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid    NVARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50)
);
GO

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           NVARCHAR(50),
    cat          NVARCHAR(50),
    subcat       NVARCHAR(50),
    maintenance  NVARCHAR(50)
);
GO
