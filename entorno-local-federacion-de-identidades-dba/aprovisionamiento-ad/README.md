# Aprovisionamiento Active Directory - Entorno de Pruebas

Scripts PowerShell para crear la estructura en Active Directory que simula el entorno de producción para la migración de usuarios Oracle a AD con Kerberos + CMU.

## Qué se crea

### Organizational Unit (OU)

| OU | Ubicación | Descripción |
|---|---|---|
| `Oracle_DB_Users` | Raíz del dominio | Contiene los usuarios de BD Oracle a federar |

### Usuarios (simulan usuarios ya existentes en AD)

Los `sAMAccountName` coinciden exactamente con los usernames de Oracle (prefijo `USR_`, mayúsculas).

| sAMAccountName | Nombre | Perfil |
|---|---|---|
| `USR_JPEREZ` | Juan Perez | Analista de ventas |
| `USR_MLOPEZ` | Maria Lopez | Ejecutivo de ventas |
| `USR_AGARCIA` | Andres Garcia | Jefe de operaciones |
| `USR_CRODRIGUEZ` | Camila Rodriguez | Analista BI |
| `USR_ETL_NIGHTLY` | ETL Nightly | Operador ETL |
| `USR_DBA_APP` | DBA Aplicativo | DBA aplicativo |

### Usuarios Oracle que NO se crean en AD

| Usuario Oracle | Tipo | Propósito |
|---|---|---|
| `APP_VENTAS` | Schema owner | Aplicación transaccional de ventas |
| `APP_INVENTARIO` | Schema owner | Gestión de inventario |
| `APP_REPORTES` | Schema owner | Reportería y BI |
| `SVC_WEBAPP` | Cuenta de servicio | Aplicación web |
| `SVC_MONITOR` | Cuenta de servicio | Monitoreo de la BD |
| `SVC_EXPDP` | Cuenta de servicio | Backups lógicos (Data Pump) |

## Prerequisitos

- Windows Server 2016 promovido a Domain Controller
- Módulo ActiveDirectory de PowerShell (incluido con el rol AD DS)
- Ejecutar como Administrador del dominio

## Uso

### Crear entorno

Desde PowerShell en el Domain Controller:

```powershell
.\01_create_ou_and_users.ps1 -Domain "laboratorio.local"
```

### Limpiar entorno

```powershell
.\99_cleanup.ps1 -Domain "laboratorio.local"
```

## Mapeo exclusivo CMU + Kerberos (Oracle 19c)

El `sAMAccountName` en AD coincide con el username en Oracle. El mapeo exclusivo se realiza por DN:

```sql
ALTER USER USR_JPEREZ IDENTIFIED GLOBALLY AS
  'CN=Juan Perez,OU=Oracle_DB_Users,DC=laboratorio,DC=local';
```

## Estructura de archivos

```
aprovisionamiento-ad/
├── 01_create_ou_and_users.ps1   # Crea OU y usuarios
├── 99_cleanup.ps1               # Limpieza
└── README.md
```
