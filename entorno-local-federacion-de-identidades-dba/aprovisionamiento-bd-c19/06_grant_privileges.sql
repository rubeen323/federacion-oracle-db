-- =============================================================================
-- 06_grant_privileges.sql
-- Otorga privilegios de sistema, objetos y roles a los usuarios
-- Ejecutar como: sqlplus / as sysdba @06_grant_privileges.sql
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- =============================================
-- Privilegios a nivel de ROLES
-- =============================================

-- rol_app_lectura: SELECT sobre tablas de ventas e inventario
GRANT SELECT ON app_ventas.clientes        TO rol_app_lectura;
GRANT SELECT ON app_ventas.productos       TO rol_app_lectura;
GRANT SELECT ON app_ventas.ordenes         TO rol_app_lectura;
GRANT SELECT ON app_ventas.detalle_ordenes TO rol_app_lectura;
GRANT SELECT ON app_ventas.v_resumen_ventas TO rol_app_lectura;
GRANT SELECT ON app_inventario.bodegas     TO rol_app_lectura;
GRANT SELECT ON app_inventario.stock       TO rol_app_lectura;

-- rol_app_escritura: INSERT/UPDATE sobre tablas transaccionales
GRANT INSERT, UPDATE ON app_ventas.clientes        TO rol_app_escritura;
GRANT INSERT, UPDATE ON app_ventas.productos       TO rol_app_escritura;
GRANT INSERT, UPDATE ON app_ventas.ordenes         TO rol_app_escritura;
GRANT INSERT, UPDATE ON app_ventas.detalle_ordenes TO rol_app_escritura;

-- rol_app_admin: todo sobre ventas e inventario
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.clientes        TO rol_app_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.productos       TO rol_app_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.ordenes         TO rol_app_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.detalle_ordenes TO rol_app_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_inventario.bodegas     TO rol_app_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_inventario.stock       TO rol_app_admin;

-- rol_reportes: SELECT sobre todo + tabla de log
GRANT SELECT ON app_ventas.v_resumen_ventas    TO rol_reportes;
GRANT SELECT ON app_ventas.clientes            TO rol_reportes;
GRANT SELECT ON app_ventas.ordenes             TO rol_reportes;
GRANT SELECT ON app_inventario.stock           TO rol_reportes;
GRANT SELECT, INSERT ON app_reportes.log_consultas TO rol_reportes;

-- rol_etl: lectura/escritura masiva
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.clientes        TO rol_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.productos       TO rol_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.ordenes         TO rol_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_ventas.detalle_ordenes TO rol_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_inventario.stock       TO rol_etl;

-- =============================================
-- Privilegios directos adicionales a usuarios especificos
-- (simula grants directos que existen en produccion)
-- =============================================

-- usr_agarcia tiene acceso directo a reportes tambien
GRANT SELECT ON app_reportes.log_consultas TO usr_agarcia;

-- usr_dba_app puede ver vistas del diccionario
GRANT SELECT ANY DICTIONARY TO usr_dba_app;

-- svc_webapp tiene grants directos sobre tablas (patron comun en apps)
GRANT SELECT, INSERT, UPDATE ON app_ventas.clientes TO svc_webapp;
GRANT SELECT, INSERT, UPDATE ON app_ventas.ordenes  TO svc_webapp;
GRANT SELECT, INSERT, UPDATE ON app_ventas.detalle_ordenes TO svc_webapp;
GRANT SELECT ON app_ventas.productos TO svc_webapp;

PROMPT >>> Privilegios otorgados exitosamente.
EXIT;
