-- =============================================================================
-- 05_create_users.sql
-- Crea usuarios de negocio que simulan usuarios de produccion a migrar
-- Incluye usuarios que SI se migraran y usuarios que NO se migraran
-- Ejecutar como: sqlplus / as sysdba @05_create_users.sql
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- =============================================
-- USUARIOS QUE SE VAN A MIGRAR A AD
-- (simulan usuarios de negocio reales)
-- =============================================

-- Analista de ventas: lectura sobre ventas
CREATE USER usr_jperez IDENTIFIED BY "Jperez2026#"
  DEFAULT TABLESPACE ts_app_data TEMPORARY TABLESPACE temp
  QUOTA 0 ON ts_app_data;
GRANT CREATE SESSION TO usr_jperez;
GRANT rol_app_lectura TO usr_jperez;

-- Ejecutivo de ventas: lectura y escritura sobre ventas
CREATE USER usr_mlopez IDENTIFIED BY "Mlopez2026#"
  DEFAULT TABLESPACE ts_app_data TEMPORARY TABLESPACE temp
  QUOTA 0 ON ts_app_data;
GRANT CREATE SESSION TO usr_mlopez;
GRANT rol_app_lectura, rol_app_escritura TO usr_mlopez;

-- Jefe de operaciones: admin de app + inventario
CREATE USER usr_agarcia IDENTIFIED BY "Agarcia2026#"
  DEFAULT TABLESPACE ts_app_data TEMPORARY TABLESPACE temp
  QUOTA 10M ON ts_app_data;
GRANT CREATE SESSION TO usr_agarcia;
GRANT rol_app_admin TO usr_agarcia;

-- Analista BI: solo reportes
CREATE USER usr_crodriguez IDENTIFIED BY "Crodrig2026#"
  DEFAULT TABLESPACE ts_reportes TEMPORARY TABLESPACE temp
  QUOTA 5M ON ts_reportes;
GRANT CREATE SESSION TO usr_crodriguez;
GRANT rol_reportes TO usr_crodriguez;

-- Operador ETL: carga de datos
CREATE USER usr_etl_nightly IDENTIFIED BY "EtlNight2026#"
  DEFAULT TABLESPACE ts_app_data TEMPORARY TABLESPACE temp
  QUOTA 50M ON ts_app_data;
GRANT CREATE SESSION TO usr_etl_nightly;
GRANT rol_etl TO usr_etl_nightly;

-- DBA aplicativo (usuario con privilegios elevados)
CREATE USER usr_dba_app IDENTIFIED BY "DbaApp2026#"
  DEFAULT TABLESPACE ts_app_data TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON ts_app_data;
GRANT CREATE SESSION, ALTER USER, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO usr_dba_app;
GRANT rol_app_admin TO usr_dba_app;

-- =============================================
-- USUARIOS QUE NO SE DEBEN MIGRAR
-- (cuentas de servicio, aplicaciones, etc.)
-- =============================================

-- Cuenta de servicio de la aplicacion web
CREATE USER svc_webapp IDENTIFIED BY "SvcWeb2026#"
  DEFAULT TABLESPACE ts_app_data TEMPORARY TABLESPACE temp
  QUOTA 0 ON ts_app_data;
GRANT CREATE SESSION TO svc_webapp;
GRANT rol_app_lectura, rol_app_escritura TO svc_webapp;

-- Cuenta de servicio para monitoreo
CREATE USER svc_monitor IDENTIFIED BY "SvcMon2026#"
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA 0 ON users;
GRANT CREATE SESSION TO svc_monitor;
GRANT SELECT_CATALOG_ROLE TO svc_monitor;

-- Cuenta de servicio para backups logicos
CREATE USER svc_expdp IDENTIFIED BY "SvcExp2026#"
  DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp
  QUOTA 0 ON users;
GRANT CREATE SESSION, DATAPUMP_EXP_FULL_DATABASE TO svc_expdp;

PROMPT >>> Usuarios de negocio y servicio creados exitosamente.
EXIT;
