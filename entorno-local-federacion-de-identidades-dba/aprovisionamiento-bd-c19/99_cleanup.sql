-- =============================================================================
-- 99_cleanup.sql
-- Elimina todo el entorno de pruebas (USAR SOLO SI SE NECESITA RECREAR)
-- Ejecutar como: sqlplus / as sysdba @99_cleanup.sql
-- =============================================================================

WHENEVER SQLERROR CONTINUE;

-- Usuarios de negocio
DROP USER usr_jperez CASCADE;
DROP USER usr_mlopez CASCADE;
DROP USER usr_agarcia CASCADE;
DROP USER usr_crodriguez CASCADE;
DROP USER usr_etl_nightly CASCADE;
DROP USER usr_dba_app CASCADE;

-- Cuentas de servicio
DROP USER svc_webapp CASCADE;
DROP USER svc_monitor CASCADE;
DROP USER svc_expdp CASCADE;

-- Schemas de aplicacion
DROP USER app_ventas CASCADE;
DROP USER app_inventario CASCADE;
DROP USER app_reportes CASCADE;

-- Roles
DROP ROLE rol_app_lectura;
DROP ROLE rol_app_escritura;
DROP ROLE rol_app_admin;
DROP ROLE rol_reportes;
DROP ROLE rol_etl;

-- Tablespaces
DROP TABLESPACE ts_app_data INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE ts_reportes INCLUDING CONTENTS AND DATAFILES;

PROMPT >>> Limpieza completada.
EXIT;
