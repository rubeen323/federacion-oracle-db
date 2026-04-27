-- =============================================================================
-- 07_verify.sql
-- Verifica que el entorno fue creado correctamente
-- Ejecutar como: sqlplus / as sysdba @07_verify.sql
-- =============================================================================

SET LINESIZE 200
SET PAGESIZE 100
COLUMN username FORMAT A20
COLUMN account_status FORMAT A20
COLUMN default_tablespace FORMAT A20
COLUMN profile FORMAT A15
COLUMN granted_role FORMAT A30
COLUMN privilege FORMAT A35
COLUMN grantee FORMAT A20
COLUMN owner FORMAT A18
COLUMN table_name FORMAT A25

PROMPT
PROMPT === USUARIOS NO ORACLE_MAINTAINED ===
SELECT username, account_status, default_tablespace, profile, created
FROM dba_users
WHERE oracle_maintained = 'N'
ORDER BY username;

PROMPT
PROMPT === ROLES PERSONALIZADOS ===
SELECT role FROM dba_roles
WHERE oracle_maintained = 'N'
ORDER BY role;

PROMPT
PROMPT === ROLES ASIGNADOS A USUARIOS ===
SELECT grantee, granted_role, admin_option, default_role
FROM dba_role_privs
WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
ORDER BY grantee, granted_role;

PROMPT
PROMPT === PRIVILEGIOS DE SISTEMA ===
SELECT grantee, privilege, admin_option
FROM dba_sys_privs
WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
ORDER BY grantee, privilege;

PROMPT
PROMPT === PRIVILEGIOS DE OBJETOS (muestra primeros 30) ===
SELECT * FROM (
  SELECT grantee, owner, table_name, privilege, grantable
  FROM dba_tab_privs
  WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
  ORDER BY grantee, owner, table_name
) WHERE ROWNUM <= 30;

PROMPT
PROMPT === TABLESPACES PERSONALIZADOS ===
SELECT tablespace_name, status, contents, extent_management
FROM dba_tablespaces
WHERE tablespace_name LIKE 'TS_%'
ORDER BY tablespace_name;

PROMPT
PROMPT === TABLAS POR SCHEMA ===
SELECT owner, table_name
FROM dba_tables
WHERE owner IN ('APP_VENTAS','APP_INVENTARIO','APP_REPORTES')
ORDER BY owner, table_name;

PROMPT
PROMPT === CONTEO DE REGISTROS ===
SELECT 'APP_VENTAS.CLIENTES' tabla, COUNT(*) registros FROM app_ventas.clientes
UNION ALL
SELECT 'APP_VENTAS.PRODUCTOS', COUNT(*) FROM app_ventas.productos
UNION ALL
SELECT 'APP_VENTAS.ORDENES', COUNT(*) FROM app_ventas.ordenes
UNION ALL
SELECT 'APP_VENTAS.DETALLE_ORDENES', COUNT(*) FROM app_ventas.detalle_ordenes
UNION ALL
SELECT 'APP_INVENTARIO.BODEGAS', COUNT(*) FROM app_inventario.bodegas
UNION ALL
SELECT 'APP_INVENTARIO.STOCK', COUNT(*) FROM app_inventario.stock;

PROMPT
PROMPT >>> Verificacion completada.
EXIT;
