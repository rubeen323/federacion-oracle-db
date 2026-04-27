-- =============================================================================
-- 02_create_roles.sql
-- Crea roles personalizados que simulan roles de negocio en produccion
-- Ejecutar como: sqlplus / as sysdba @02_create_roles.sql
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Rol para lectura de datos transaccionales
CREATE ROLE rol_app_lectura;

-- Rol para escritura de datos transaccionales
CREATE ROLE rol_app_escritura;

-- Rol para administracion de esquemas de aplicacion
CREATE ROLE rol_app_admin;

-- Rol para consultas de reportes/BI
CREATE ROLE rol_reportes;

-- Rol para operaciones batch/ETL
CREATE ROLE rol_etl;

PROMPT >>> Roles creados exitosamente.
EXIT;
