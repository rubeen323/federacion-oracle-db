-- =============================================================================
-- 03_create_schemas.sql
-- Crea schemas de aplicacion con tablas y datos de prueba
-- Ejecutar como: sqlplus / as sysdba @03_create_schemas.sql
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- =============================================
-- Schema: APP_VENTAS (aplicacion transaccional)
-- =============================================
CREATE USER app_ventas IDENTIFIED BY "AppVentas2026#"
  DEFAULT TABLESPACE ts_app_data
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON ts_app_data;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE,
      CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER TO app_ventas;

-- =============================================
-- Schema: APP_INVENTARIO
-- =============================================
CREATE USER app_inventario IDENTIFIED BY "AppInv2026#"
  DEFAULT TABLESPACE ts_app_data
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON ts_app_data;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE,
      CREATE VIEW, CREATE PROCEDURE TO app_inventario;

-- =============================================
-- Schema: APP_REPORTES (BI/reporteria)
-- =============================================
CREATE USER app_reportes IDENTIFIED BY "AppRep2026#"
  DEFAULT TABLESPACE ts_reportes
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON ts_reportes;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO app_reportes;

PROMPT >>> Schemas de aplicacion creados exitosamente.
EXIT;
