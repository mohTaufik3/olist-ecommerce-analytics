# Bronze Layer: Brazilian E-Commerce (Olist)

The **Bronze** layer is the first stage of the Medallion architecture
(Bronze → Silver → Gold). Its purpose is to load raw CSV data into SQL Server
**as is**, without any transformation, so there is always a copy of the source
data that can be reprocessed.

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(Kaggle), consisting of 9 CSV files.

## Folder Contents

| File | Purpose |
|------|---------|
| `init_database.sql` | Creates the `BrazillianECommerce` database and the `bronze`, `silver`, and `gold` schemas. **Drops the existing database if it exists.** |
| `ddl_bronze.sql` | Creates the 9 bronze tables (DROP + CREATE). |
| `proc_load_bronze.sql` | Stored procedure `bronze.load_bronze` that loads all CSV files (TRUNCATE + BULK INSERT). |

## Tables and Row Counts

| Table | Source file | Rows |
|-------|-------------|-----:|
| `bronze.customers` | `olist_customers_dataset.csv` | 99,441 |
| `bronze.geolocation` | `olist_geolocation_dataset.csv` | 1,000,163 |
| `bronze.order_items` | `olist_order_items_dataset.csv` | 112,650 |
| `bronze.order_payments` | `olist_order_payments_dataset.csv` | 103,886 |
| `bronze.order_reviews` | `olist_order_reviews_dataset.csv` | 99,224 |
| `bronze.orders` | `olist_orders_dataset.csv` | 99,441 |
| `bronze.products` | `olist_products_dataset.csv` | 32,951 |
| `bronze.sellers` | `olist_sellers_dataset.csv` | 3,095 |
| `bronze.category_name_translation` | `product_category_name_translation.csv` | 71 |

## How to Run

1. Download the dataset and place the CSV files in a single folder.
2. Update the `D:\BUILD-PORTOFOLIO\...` path in `proc_load_bronze.sql` to match your file location.
3. Grant the SQL Server service account **Read** permission on that folder. Find the account with:
```sql
   SELECT servicename, service_account FROM sys.dm_server_services;
```
4. Run the scripts in order:
```sql
   -- 1) init_database.sql
   -- 2) ddl_bronze.sql
   -- 3) proc_load_bronze.sql
   EXEC bronze.load_bronze;
```

The procedure can be run repeatedly because each table is truncated before it is loaded.

## Design Decisions

- **Data is stored as is.** Cleaning and type conversion happen in the Silver layer.
- **Zip codes use `NVARCHAR`.** Leading zeros (e.g. `01151`) are lost if stored as `INT`.
- **`order_reviews` columns are text.** This file contains free-text comments with commas, quotes, and line breaks, so type conversion during load is prone to failure.
- **Source column typos are preserved** (`product_name_lenght`, `product_lenght_cm`). They are fixed in Silver.
- **Errors are re-thrown (`THROW`)** so a failed load never looks like a successful one.

## BULK INSERT Options per Table

| Table | Mode | Reason |
|-------|------|--------|
| customers, order_items, order_payments, orders, products, sellers, category_name_translation | `FORMAT='CSV'` + `ROWTERMINATOR='0x0a'` | Quoted values are parsed correctly; files use LF line endings. |
| geolocation | non-CSV + `CODEPAGE='65001'` | Keeps accented characters (e.g. `guaçu`) intact. |
| order_reviews | `FORMAT='CSV'` without `ROWTERMINATOR` | Multi-line text inside quotes must be handled by the CSV parser. |

## Troubleshooting

| Error | Common cause | Fix |
|-------|--------------|-----|
| `7301` (`IID_IColumnsInfo`) | File cannot be read, or the option combination is incompatible (e.g. `FORMAT='CSV'` + `CODEPAGE`). | Check folder permissions and path; reduce options to the ones proven to work. |
| `4866` (column too long) | `ROWTERMINATOR` does not match; the whole file is read as one row. | Use `0x0a` (LF) or `0x0d0a` (CRLF). |
| `4863` / `4864` | Rows split by multi-line text, or column type mismatch. | Use `FORMAT='CSV'`; make the columns `NVARCHAR`. |
| `102` (syntax error) | Non-SQL text was pasted into the query window. | Use a clean, empty New Query window. |
| Text like `s├úo paulo` | UTF-8 data read with a legacy code page. | Add `CODEPAGE='65001'` (test per table first). |

## Post-Load Verification

```sql
-- Remaining quotes (should be 0)
SELECT COUNT(*) FROM bronze.customers
WHERE customer_id LIKE '%"%' OR customer_city LIKE '%"%';

-- Zip codes must keep leading zeros
SELECT TOP 5 customer_zip_code_prefix FROM bronze.customers
WHERE customer_zip_code_prefix LIKE '0%';

-- Accented characters must be intact
SELECT TOP 5 geolocation_city FROM bronze.geolocation
WHERE geolocation_city LIKE '%[^a-z ]%';
```

## Next Step

**Silver layer**: data type conversion, handling of missing values, column name
standardization, deduplication (especially `geolocation`), and joining product
category translations.
