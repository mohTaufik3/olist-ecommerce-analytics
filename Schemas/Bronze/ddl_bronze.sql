/*
===============================================================================
Objective		: To create 9 Bronze layer tables for the Olist dataset (Brazilian E-Commerce).
Principle		: Bronze stores data as per its source, without any transformation.
Data cleansing and type conversion are carried out in the Silver layer.
Note			: This script DROPS and then RECREATES the tables, so the table contents will be lost.
Re-run bronze.load_bronze afterwards.
===============================================================================
*/

-- ============================ customers ====================================
IF OBJECT_ID('bronze.customers', 'U') IS NOT NULL
	DROP TABLE bronze.customers;
GO

CREATE TABLE bronze.customers ( 
	customer_id					NVARCHAR(200),
	customer_unique_id			NVARCHAR(200),
-- The postcode must be in text format so that any leading zeros are not lost (e.g. '01151').
-- If it is an INT, the value becomes 1151, which is incorrect.
	customer_zip_code_prefix	NVARCHAR(100), 
	customer_city				NVARCHAR(200), 
	customer_state				NVARCHAR(100)
);
GO

-- ============================ geolocation ==================================
IF OBJECT_ID('bronze.geolocation', 'U') IS NOT NULL
	DROP TABLE bronze.geolocation;
GO

CREATE TABLE bronze.geolocation (
	geolocation_zip_code_prefix NVARCHAR(50), -- text; same reasoning as for ‘customers’
	-- Coordinates are in long decimal format (e.g. -23.545621...), so INT is not permitted.
	geolocation_lat				DECIMAL(20,15),
	geolocation_lng				DECIMAL(20,15),
	geolocation_city			NVARCHAR(50),
	geolocation_state			NVARCHAR(50)
);
GO

-- ============================ order_items ==================================
IF OBJECT_ID('bronze.order_items', 'U') IS NOT NULL
	DROP TABLE bronze.order_items;
GO

CREATE TABLE bronze.order_items (
	order_id					NVARCHAR(100),
	order_item_id				INT,
	product_id					NVARCHAR(100),
	seller_id					NVARCHAR(100),
	shipping_limit_date			DATETIME,
	price						DECIMAL(10,2),
	freight_value				DECIMAL(10,2)
	-- The number/date type has already been used directly and the load was successful.
	-- A safer option: use NVARCHAR in Bronze, convert in Silver,
	-- so that the load does not fail if, one day, there are empty values or different formats.
);
GO

-- ============================ order_payments ===============================
IF OBJECT_ID('bronze.order_payments', 'U') IS NOT NULL
	DROP TABLE bronze.order_payments;
GO

CREATE TABLE bronze.order_payments (
	order_id					NVARCHAR(100),
	payment_sequential			INT,
	payment_type				NVARCHAR(50),
	payment_installments		INT,
	payment_value				NVARCHAR(50)  -- loaded as text, converted to DECIMAL in Silver
);
GO

-- ============================ order_reviews ================================
IF OBJECT_ID('bronze.order_reviews', 'U') IS NOT NULL
    DROP TABLE bronze.order_reviews;
GO

-- All non-text columns are defined as NVARCHAR because this file is the ‘dirtiest’:
-- the review comments contain commas, quotation marks and new lines. With text,
-- conversion errors (4863/4864) do not occur during the load.
CREATE TABLE bronze.order_reviews (
    review_id               NVARCHAR(100),
    order_id                NVARCHAR(100),
    review_score            NVARCHAR(10),
    review_comment_title    NVARCHAR(MAX),
    review_comment_message  NVARCHAR(MAX),
    review_creation_date    NVARCHAR(50),
    review_answer_timestamp NVARCHAR(50)
);
GO

-- ============================ orders =======================================
IF OBJECT_ID('bronze.orders', 'U') IS NOT NULL
	DROP TABLE bronze.orders;
GO

CREATE TABLE bronze.orders (
	order_id						NVARCHAR(100),
	customer_id						NVARCHAR(100),
	order_status					NVARCHAR(50),
	order_purchase_timestamp		DATETIME,
-- The date column below may be left blank for orders that have not yet
-- been approved/dispatched/received. The column is nullable (by default), so it’s safe.
	order_approved_at				DATETIME,
	order_delivered_carrier_date	DATETIME,
	order_delivered_customer_date	DATETIME,
	order_estimated_delivery_date	DATETIME
);
GO

-- ============================ products =====================================
IF OBJECT_ID('bronze.products', 'U') IS NOT NULL
	DROP TABLE bronze.products;
GO

CREATE TABLE bronze.products (
	product_id					NVARCHAR(100),
	product_category_name		NVARCHAR(100),
	product_name_length			INT,
	product_description_length	INT,
	product_photos_qty			INT,
	product_weight_g			INT,
	product_length_cm			INT,
	product_height_cm			INT,
	product_width_cm			INT
);
GO

-- ============================ sellers ======================================
IF OBJECT_ID('bronze.sellers', 'U') IS NOT NULL
	DROP TABLE bronze.sellers;
GO

CREATE TABLE bronze.sellers (
	seller_id					NVARCHAR(100),
	seller_zip_code_prefix		NVARCHAR(50),
	seller_city					NVARCHAR(100),
	seller_state				NVARCHAR(50)
);
GO

-- ============================ category_name_translation ====================
IF OBJECT_ID('bronze.category_name_translation', 'U') IS NOT NULL
	DROP TABLE bronze.category_name_translation;
GO

-- Reference table: Portuguese category names → English.
CREATE TABLE bronze.category_name_translation (
	product_category_name			NVARCHAR(50),
	product_category_name_english	NVARCHAR(50)
);
GO