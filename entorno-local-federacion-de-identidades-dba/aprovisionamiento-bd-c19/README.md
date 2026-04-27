# Aprovisionamiento BD Oracle 19c - Entorno de Pruebas

Scripts SQL para crear un entorno que simula una base de datos Oracle 19c Enterprise Edition non-CDB en producción, con schemas, tablas, usuarios de negocio, roles y privilegios.

## Qué se crea

### Tablespaces
| Tablespace | Propósito |
|---|---|
| `TS_APP_DATA` | Datos de aplicaciones transaccionales |
| `TS_REPORTES` | Datos de reportería/BI |

### Schemas de aplicación (dueños de objetos)
| Schema | Descripción | Tablas |
|---|---|---|
| `APP_VENTAS` | Aplicación transaccional de ventas | clientes, productos, ordenes, detalle_ordenes, v_resumen_ventas |
| `APP_INVENTARIO` | Gestión de inventario | bodegas, stock |
| `APP_REPORTES` | Reportería y BI | log_consultas |

### Roles de negocio
| Rol | Privilegios |
|---|---|
| `ROL_APP_LECTURA` | SELECT sobre tablas de ventas e inventario |
| `ROL_APP_ESCRITURA` | INSERT/UPDATE sobre tablas transaccionales |
| `ROL_APP_ADMIN` | CRUD completo sobre ventas e inventario |
| `ROL_REPORTES` | SELECT sobre vistas y tablas de reporte |
| `ROL_ETL` | CRUD para carga masiva de datos |

### Usuarios de negocio (a migrar a AD)
| Usuario | Perfil simulado | Roles |
|---|---|---|
| `USR_JPEREZ` | Analista de ventas | rol_app_lectura |
| `USR_MLOPEZ` | Ejecutivo de ventas | rol_app_lectura, rol_app_escritura |
| `USR_AGARCIA` | Jefe de operaciones | rol_app_admin |
| `USR_CRODRIGUEZ` | Analista BI | rol_reportes |
| `USR_ETL_NIGHTLY` | Operador ETL | rol_etl |
| `USR_DBA_APP` | DBA aplicativo | rol_app_admin + privilegios de sistema |

### Cuentas de servicio (NO migrar a AD)
| Usuario | Propósito | Roles |
|---|---|---|
| `SVC_WEBAPP` | Cuenta de la aplicación web | rol_app_lectura, rol_app_escritura + grants directos |
| `SVC_MONITOR` | Monitoreo de la BD | SELECT_CATALOG_ROLE |
| `SVC_EXPDP` | Backups lógicos (Data Pump) | DATAPUMP_EXP_FULL_DATABASE |

## Prerequisitos

En la VM RHEL 8.10 con Oracle 19c instalado:

```bash
# Conectarse como usuario oracle
sudo su - oracle

# Verificar variables de entorno
echo $ORACLE_HOME    # Ej: /u01/app/oracle/product/19.0.0/dbhome_1
echo $ORACLE_SID     # Debe ser: orcl2

# Si no están configuradas:
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=orcl2
export PATH=$ORACLE_HOME/bin:$PATH

# Verificar que la BD está levantada
sqlplus / as sysdba <<< "SELECT STATUS FROM V\$INSTANCE;"
```

> **Nota:** Ajusta `ORACLE_HOME` según tu instalación. Puedes verificar la ruta con `cat /etc/oratab`.

## Ruta de datafiles

Los scripts asumen que los datafiles se crean en `/u01/app/oracle/oradata/ORCL2/`. Si tu BD usa otra ruta, edita `01_setup_tablespaces.sql` antes de ejecutar. Para verificar la ruta correcta:

```sql
SELECT FILE_NAME FROM DBA_DATA_FILES WHERE ROWNUM = 1;
```

## Uso

### Opción 1: Ejecutar todo de una vez

Copiar los scripts a la VM y ejecutar:

```bash
cd /ruta/donde/copiaste/los/scripts
chmod +x run_all.sh
./run_all.sh
```

### Opción 2: Ejecutar script por script

```bash
sqlplus / as sysdba @01_setup_tablespaces.sql
sqlplus / as sysdba @02_create_roles.sql
sqlplus / as sysdba @03_create_schemas.sql
sqlplus / as sysdba @04_create_tables.sql
sqlplus / as sysdba @05_create_users.sql
sqlplus / as sysdba @06_grant_privileges.sql
sqlplus / as sysdba @07_verify.sql
```

## Limpieza

Para eliminar todo y recrear desde cero:

```bash
sqlplus / as sysdba @99_cleanup.sql
```

## Orden de ejecución

```
01_setup_tablespaces.sql  → Tablespaces
02_create_roles.sql       → Roles de negocio
03_create_schemas.sql     → Schemas (dueños de objetos)
04_create_tables.sql      → Tablas + datos de prueba
05_create_users.sql       → Usuarios de negocio y servicio
06_grant_privileges.sql   → Privilegios sobre objetos
07_verify.sql             → Verificación del entorno
99_cleanup.sql            → Limpieza (solo si se necesita recrear)
```
