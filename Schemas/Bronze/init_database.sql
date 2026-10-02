/*
===============================================================================
Purpose     : To recreate the 'BrazillianECommerce' database along with the three
Medallion architecture schemas (bronze, silver, gold).
WARNING     : This script DELETES the old database if it already exists. All data
within it will be lost. Run only during initial setup or a complete reset.
===============================================================================
*/

USE master;
GO

-- Delete the old database, if any.
-- SINGLE_USER + ROLLBACK IMMEDIATE terminates all active connections,
-- as a database that is currently in use cannot be DROPPED.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BrazillianECommerce')
BEGIN
    ALTER DATABASE BrazillianECommerce SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BrazillianECommerce;
END;
GO

CREATE DATABASE BrazillianECommerce;
GO

USE BrazillianECommerce;
GO

-- One schema per layer, so that the tables for each layer are neatly separated:
CREATE SCHEMA bronze; -- raw data, as-is from the CSV file
GO
CREATE SCHEMA silver; -- data that has been cleaned and had its data types converted
GO
CREATE SCHEMA gold; -- data ready for analysis / dashboards
GO