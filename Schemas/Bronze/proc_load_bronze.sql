/*
===============================================================================
Procedure       : bronze.load_bronze
Purpose         : To load 9 Olist CSV files into the Bronze layer table (full load).
Pattern         : For each table:
                    TRUNCATE (clear) then BULK INSERT (reload). The procedure is safe to run repeatedly;
                    the results are always the same.
Usage           : EXEC bronze.load_bronze;
Prerequisites   : - The SQL Server service account must have read permission to the CSV folder.
                  - The file path must be accessible from the machine on which SQL Server is running.
                  - Change the path ‘D:\...’ to match the location of your files.


BULK INSERT options used and their reasons  :
FORMAT = ‘CSV’          : reads standard CSV files. Quoted values ("...") are read
correctly and the quotation marks are not saved.
FIELDQUOTE = '"'        : value delimiter. Only works with FORMAT='CSV'.
FIRSTROW = 2            : row 1 is the header and is skipped.
ROWTERMINATOR = '0x0a'  : the file uses LF as the line separator (not CRLF).
Without this, the entire file is read as one long line
(error 4866).
CODEPAGE = '65001'      : the file is encoded in UTF-8. Used in geolocation to ensure that accented characters
(e.g. 'guaçu') are not corrupted.
TABLOCK                 : locks the table during loading to speed up the process.


Findings during testing (important if you change the options):
    - FORMAT='CSV' + CODEPAGE triggers error 7301 in this environment, so
    that combination is not used.
    - Without FORMAT='CSV', quotation marks are included in the data (e.g. "01151").
    - order_reviews contains multi-line text within quotation marks, so CSV mode is mandatory
    and an explicit ROWTERMINATOR must not be used.
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        -- ---------------------------------------------------------------
        -- customers: CSV + LF format.
        -- There are both quoted and unquoted values in a single file;
        -- FORMAT='CSV' handles both.
        -- ---------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.customers';
        TRUNCATE TABLE bronze.customers;
        BULK INSERT bronze.customers
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_customers_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- ---------------------------------------------------------------
        -- geolocation: non-CSV mode + UTF-8.
        -- Contains approximately 1 million rows with accented city names. This combination has
        -- been shown to preserve accented characters.
        -- ---------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.geolocation';
        TRUNCATE TABLE bronze.geolocation;
        BULK INSERT bronze.geolocation
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_geolocation_dataset.csv'
        WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- order_items: CSV mode + LF.
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.order_items';
        TRUNCATE TABLE bronze.order_items;
        BULK INSERT bronze.order_items
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_order_items_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- order_payments: CSV mode + LF.
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.order_payments';
        TRUNCATE TABLE bronze.order_payments;
        BULK INSERT bronze.order_payments
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_order_payments_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- ---------------------------------------------------------------
        -- order_reviews: CSV mode WITHOUT ROWTERMINATOR.
        -- Review comments contain commas and new lines within the quotes, so
        -- the CSV parser must determine the line boundaries itself. Adding
        -- ROWTERMINATOR/CODEPAGE here triggers error 7301.
        -- ---------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.order_reviews';
        TRUNCATE TABLE bronze.order_reviews;
        BULK INSERT bronze.order_reviews
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_order_reviews_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- orders: mode CSV + LF.
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.orders';
        TRUNCATE TABLE bronze.orders;
        BULK INSERT bronze.orders
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_orders_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- products: CSV mode + LF.
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.products';
        TRUNCATE TABLE bronze.products;
        BULK INSERT bronze.products
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_products_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- sellers: CSV mode + LF.
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.sellers';
        TRUNCATE TABLE bronze.sellers;
        BULK INSERT bronze.sellers
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\olist_sellers_dataset.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- category_name_translation: CSV mode + LF
        SET @start_time = GETDATE();
        PRINT '>> Loading: bronze.category_name_translation';
        TRUNCATE TABLE bronze.category_name_translation;
        BULK INSERT bronze.category_name_translation
        FROM 'D:\BUILD-PORTOFOLIO\Brazillian - Dashboard\Data\product_category_name_translation.csv'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', ROWTERMINATOR='0x0a', TABLOCK);
        SET @end_time = GETDATE();
        PRINT '   Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        SET @batch_end_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        -- Print error details for diagnosis. ERROR_LINE() indicates the line
        -- of the BULK INSERT that failed, so the affected table is easy to trace.
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line   : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================';

        -- THROW re-throws the error. Without this, the procedure appears to have succeeded
        -- even though it has failed, which is dangerous if it is later scheduled to run automatically.
        THROW;
    END CATCH
END
GO

-- Run this in a separate query if you do not want it to be executed automatically:
EXEC bronze.load_bronze;