-- =============================================================================
-- 01_setup_tablespaces.sql
-- Crea tablespaces para simular un entorno productivo Oracle 19c non-CDB
-- Ejecutar como: sqlplus / as sysdba @01_setup_tablespaces.sql
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Tablespace para datos de aplicaciones
CREATE TABLESPACE ts_app_data
  DATAFILE '/u01/app/oracle/oradata/ORCL2/ts_app_data01.dbf' SIZE 100M
  AUTOEXTEND ON NEXT 50M MAXSIZE 500M
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO;

-- Tablespace para datos de reportes/BI
CREATE TABLESPACE ts_reportes
  DATAFILE '/u01/app/oracle/oradata/ORCL2/ts_reportes01.dbf' SIZE 50M
  AUTOEXTEND ON NEXT 25M MAXSIZE 200M
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO;

PROMPT >>> Tablespaces creados exitosamente.
EXIT;
