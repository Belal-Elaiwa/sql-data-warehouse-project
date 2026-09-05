/*
Develop SQL Load Scripts
Using Bulk Insertion
Suitable for large tables, better than INSERT --> Row by Row
Syntax:

BULK INSERT table_name 
FROM 'FilePath on your Computer'
WITH (
	FIRST ROW = 2,             --> Row 1 is the header, the data starts from row 2!
	FIELD TERMINATOR = ',',    --> May be , or # or : or ; --> According to your Source Files!
	TABLOCK                   --> To improve performance like you're locking the entire table during loading it!
)

Test the quality of your bronze layer 
SELECT * FROM table_name;
SELECT COUNT(*) FROM table_name;
	- Do we have data in each column ?
	- Do we have the data in the right column ?
	  Check that the data has not shifted and is in the correct columns
	- Compare the count of rows 
	  we always have 1 less row than the original file | Cuz of the header
---------------------------------------------------------------------------------------
TRUNCATE 
Quickly delete all rows from a table, resetting it to an empty state
Do it before the BULK INSERT To avoid Data duplication!

TRUCATE TABLE table_name;

BULK INSERT table_name
FROM 'FilePath'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ','
	TABLOCK
);
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
HINT:
Save frequently used SQL code in Stored Procedures in Database!
Syntax:
 
 CREATE OR ALTER PROCESURE SP_name_following_convention AS
 BEGIN
	TRUNCATE TABLE 
	BULK INSERT ...;
	
	TRUNCATE TABLE 
	BULK INSERT ...;

	TRUNCATE TABLE 
	BULK INSERT ...;
 END
 EXEC SP_name
 ------------------------------------------------------------------------------------
Add PRINTS:
Add Prints to track execution, debug issues, and understand its flow!!

Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
-- Craeting the bronze layer for DataWarehouse 
-- Tables creation 
-- Exploring or analyzing the columns and its data 
-- We have two sources
--------------------------------------------------------
-- source_crm (cust_info, prd_info, sales_details)

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_cust_info;
GO
CREATE TABLE bronze.crm_cust_info (
	cst_id             INT,
	cst_key            NVARCHAR(50),
	cst_firstname      NVARCHAR(50),
	cst_lastname       NVARCHAR(50),
	cst_marital_status NVARCHAR(10),
	cst_gndr           NVARCHAR(50),
	cst_create_date    NVARCHAR(50)
);

GO

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_prd_info;
GO
CREATE TABLE bronze.crm_prd_info(
	prd_id       INT,
	prd_key      NVARCHAR(50),
	prd_nm       NVARCHAR(50),
	prd_cost     INT,
	prd_line     NVARCHAR(50),
	prd_start_dt DATETIME,
	prd_end_dt   NVARCHAR(50)
);

GO

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;
GO
CREATE TABLE bronze.crm_sales_details (
	sls_ord_num  NVARCHAR(50),
	sls_prd_key  NVARCHAR(50),
	sls_cust_id  INT,
	sls_order_dt NVARCHAR(50),
	sls_ship_dt  DATETIME,
	sls_due_dt   DATETIME,
	sls_sales    INT,
	sls_quantity INT,
	sls_price    INT
);

GO
---------------------------------------------------------
-- source_erp (CUST_AZ12, LOC_A101, PX_CAT_G1V2)

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE bronze.erp_cust_az12;
GO 
CREATE TABLE bronze.erp_cust_az12(
	CID   NVARCHAR(50),
	BDATE DATETIME,
	GEN   NVARCHAR(50)
);

GO

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE bronze.erp_loc_a101;
GO
CREATE TABLE bronze.erp_loc_a101(
	CID   NVARCHAR(50),
	CNTRY NVARCHAR(50)
);

GO 

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE bronze.erp_px_cat_g1v2;
GO
CREATE TABLE bronze.erp_px_cat_g1v2(
	ID          NVARCHAR(50),
	CAT         NVARCHAR(50),
	SUBCAT      NVARCHAR(50),
	MAINTENANCE NVARCHAR(50)
);

/* 
==============================================================
Bronze Layer | Loading Data
---------------------------
Full Load | Bulk Insertion 
==============================================================*/
-- source_crm (bronze_crm_cust_info, bronze_crm_prd_info, bronze_crm_sales_details)
TRUNCATE TABLE bronze.crm_cust_info;

BULK INSERT bronze.crm_cust_info
FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
/*
During Bulk insertion there was an error about data type mismatch 
in bronze_crm_cust_info (cst_create_date    NVARCHAR(50)) i created it 
as DATETIME but in the CSV file it is date but with the format dd/mm/yyyy
so, I reExecuted the script and changed the type into NVARCHAR(50)
as we are in the bronze layer ..!

Also for
bronze_crm_prd_info (prd_end_dt)
bronze_crm_sales_details(sls_order_dt)
*/

TRUNCATE TABLE bronze.crm_prd_info;
BULK INSERT bronze.crm_prd_info
FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);

GO

TRUNCATE TABLE bronze.crm_sales_details;
BULK INSERT bronze.crm_sales_details
FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
)
-- source_erp (bronze_erp_cust_az12, bronze_erp_loc_a101, bronze_erp_px_cat_g1v2)

TRUNCATE TABLE bronze.erp_cust_az12;
BULK INSERT bronze.erp_cust_az12
FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
WITH(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);

GO 

TRUNCATE TABLE bronze.erp_loc_a101;
BULK INSERT bronze.erp_loc_a101
FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
WITH( 
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);

GO
TRUNCATE TABLE bronze.erp_px_cat_g1v2;
BULK INSERT bronze.erp_px_cat_g1v2
FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
WITH( 
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
)
--======================================================================================================================
-- Stored Procedure for the whole script

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	TRUNCATE TABLE bronze.crm_cust_info;
	BULK INSERT bronze.crm_cust_info
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	TRUNCATE TABLE bronze.crm_prd_info;
	BULK INSERT bronze.crm_prd_info
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	TRUNCATE TABLE bronze.crm_sales_details;
	BULK INSERT bronze.crm_sales_details
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	)
	-- source_erp (bronze_erp_cust_az12, bronze_erp_loc_a101, bronze_erp_px_cat_g1v2)

	TRUNCATE TABLE bronze.erp_cust_az12;
	BULK INSERT bronze.erp_cust_az12
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	TRUNCATE TABLE bronze.erp_loc_a101;
	BULK INSERT bronze.erp_loc_a101
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
	WITH( 
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	BULK INSERT bronze.erp_px_cat_g1v2
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
	WITH( 
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);
END

EXEC bronze.load_bronze

--------------------------------------------------------------------------------------------------------------------
-- Adding or printing simple messages to clarify the steps/sections in the script

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	PRINT '====================================================================================================================';
	PRINT 'Loading Bronze Layer'
	PRINT '====================================================================================================================';
	
	PRINT '--------------------------------------------------------------------------------------------------------------------';
	PRINT 'Loading CRM Tables'
	PRINT '--------------------------------------------------------------------------------------------------------------------';
	
	PRINT '>> Truncating Table: bronze.crm_cust_info';
	TRUNCATE TABLE bronze.crm_cust_info;

	PRINT '>> Inserting Data into: bronze.crm_cust_info';
	BULK INSERT bronze.crm_cust_info
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);
	PRINT '>> Truncating Table: bronze.crm_prd_info';
	TRUNCATE TABLE bronze.crm_prd_info;

	PRINT '>> Inserting Data into: bronze.crm_prd_info';
	BULK INSERT bronze.crm_prd_info
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	PRINT '>> Truncating Table: bronze.crm_sales_details';
	TRUNCATE TABLE bronze.crm_sales_details;

	PRINT '>> Inserting Data into: bronze.crm_sales_details'
	BULK INSERT bronze.crm_sales_details
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	)
	-- source_erp (bronze_erp_cust_az12, bronze_erp_loc_a101, bronze_erp_px_cat_g1v2)
	PRINT '--------------------------------------------------------------------------------------------------------------------'
	PRINT 'Loading ERP Tables'
	PRINT '--------------------------------------------------------------------------------------------------------------------'

	PRINT '>> Truncating Table: bronze.erp_cust_az12';
	TRUNCATE TABLE bronze.erp_cust_az12;

	PRINT '>> Inserting Data into: bronze.erp_cust_az12'
	BULK INSERT bronze.erp_cust_az12
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
	WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	PRINT '>> Truncating Table: bronze.erp_loc_a101';
	TRUNCATE TABLE bronze.erp_loc_a101;

	PRINT '>> Inserting Data into: bronze.erp_loc_a101'
	BULK INSERT bronze.erp_loc_a101
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
	WITH( 
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;

	PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2'
	BULK INSERT bronze.erp_px_cat_g1v2
	FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
	WITH( 
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);
END

EXEC bronze.load_bronze
--------------------------------------------------------------------------------------
/*
Add TRY .. CATCH 
Ensure error handling, data integrity, and issue logging for easier debugging

HINT:
BEGIN
	BEGIN TRY
	END TRY
	BEGIN CATCH 
	END CATCH
END 
all will be inside the stored procedure!

SQL runs the TRY block, and if it fails, it runs the CATCH block to handle the error
--------------------------------------------------------------------------------------
Track ETL Duration
Helps to identify bottlenecks, optimize performance, monitor trends, detect issues 
For example I want to know how long did it take to load a specific table? */


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	BEGIN TRY
		PRINT '====================================================================================================================';
		PRINT 'Loading Bronze Layer'
		PRINT '====================================================================================================================';
	
		PRINT '--------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '--------------------------------------------------------------------------------------------------------------------';
		
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data into: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		PRINT '--------------------------------------------------------------------------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------------------------------------------------------------------------------------------------------'

		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data into: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data into: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
	END TRY
	BEGIN CATCH
		PRINT '============================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
	END CATCH
END

EXEC bronze.load_bronze

---------------------------------------------------------------------------------------------------------------------
/*
Calculate the duration: We need a Start Time & End Time
Declare variables !
Use DATEDIFF()
	Calculates the difference between two dates, returns days, months, or years
Calculate the Duration of ALL BRONZE TABLES
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY
		PRINT '====================================================================================================================';
		PRINT 'Loading Bronze Layer'
		PRINT '====================================================================================================================';
	
		PRINT '--------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '--------------------------------------------------------------------------------------------------------------------';

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data into: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '--------------------------------------------------------------------------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------------------------------------------------------------------------------------------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data into: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data into: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
	END TRY
	BEGIN CATCH
		PRINT '============================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
	END CATCH
END

EXEC bronze.load_bronze
----------------------------------------------------------------------------------------------------------
-- Calculate the Duration of Loading Bronze Layer "Whole Batch"

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	
	BEGIN TRY
		SET @batch_start_time = GETDATE()
		PRINT '====================================================================================================================';
		PRINT 'Loading Bronze Layer'
		PRINT '====================================================================================================================';
	
		PRINT '--------------------------------------------------------------------------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '--------------------------------------------------------------------------------------------------------------------';

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting Data into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data into: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '--------------------------------------------------------------------------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------------------------------------------------------------------------------------------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data into: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data into: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\Belal Data\Project practice\SQL BARAA\WareHousing\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'Seconds'
		PRINT '--------------------------------------------------------------------------------------------'
		
		SET @batch_end_time = GETDATE()
		PRINT '============================================================';
		PRINT 'Loading Bronze Layer is Completed';
		PRINT '	  - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'Seconds'
		PRINT '============================================================';
	END TRY 
	BEGIN CATCH
		PRINT '============================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
	END CATCH
END

EXEC bronze.load_bronze
END
