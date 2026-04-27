# Federación de Identidades Oracle 12c con Active Directory (Kerberos puro)

Playbooks de Ansible para migrar usuarios locales de bases de datos Oracle Enterprise Edition 12.1/12.2 a autenticación centralizada con Active Directory usando Kerberos puro (`IDENTIFIED EXTERNALLY`).

## Diferencia con Oracle 19c (CMU)

| Aspecto | Oracle 12.1/12.2 (este proyecto) | Oracle 19c (proyecto -dba) |
|---|---|---|
| Método | Kerberos puro | Kerberos + CMU |
| Comando SQL | `ALTER USER x IDENTIFIED EXTERNALLY AS 'user@REALM'` | `ALTER USER x IDENTIFIED GLOBALLY AS '<DN>'` |
| Auth type resultante | `EXTERNAL` | `GLOBAL` |
| dsi.ora / wallet CMU | No aplica | Requerido |
| LDAP_DIRECTORY_ACCESS | No aplica | `PASSWORD` |
| LDAP_DIRECTORY_SYSAUTH | No aplica | `YES` |
| Oracle consulta AD | No (solo valida ticket Kerberos) | Sí (vía LDAPS) |
| opwdintg.exe | No aplica | No (solo si auth por password) |

## Playbooks

| # | Playbook | Descripción | Vault |
|---|---|---|---|
| 1 | `1-oracle_users_discovery.yml` | Descubre usuarios, privilegios, roles. Compatible 12.1 (sin `oracle_maintained`). | Sí |
| 2 | `2-crossref_oracle_ad.yml` | Cruza usuarios Oracle vs AD vía LDAPS. | Sí |
| 3 | `3-spn_report.yml` | Reporte de SPNs por servidor. | No |
| 4 | `4-register_spn_keytab.yml` | Registra SPNs y genera keytabs (AES256). | Sí |
| 5 | `5-check_sqlnet.yml` | Verifica sqlnet.ora (solo lectura). | No |
| 6 | `6-configure_sqlnet_kerberos.yml` | Configura Kerberos en sqlnet.ora. | No |
| 7 | `7-configure_krb5_conf.yml` | Configura /etc/krb5.conf. | No |
| 8 | `8-configure_os_authent_prefix.yml` | `OS_AUTHENT_PREFIX=''` (SPFILE, requiere restart). | Sí |
| 9 | `9-backup_password_hashes.yml` | Respalda hashes de SYS.USER$ + script SQL de restauración. | Sí |
| 10 | `10-migrate_users_to_kerberos.yml` | `ALTER USER IDENTIFIED EXTERNALLY AS '<user@REALM>'`. | Sí |
| 11 | `11-validate_migration.yml` | Valida auth=EXTERNAL y privilegios intactos. | Sí |
| 12 | `12-rollback_migration.yml` | Revierte en 2 capas: usuarios + config RHEL. | Sí |

## Orden de ejecución

```
 1.  [AD]     Crear cuenta de servicio Kerberos (AES256 habilitado)
 2.  [AD]     Habilitar AES256 en cuentas de usuario a migrar
 3.  [RHEL]   Verificar resolución DNS (DC y FQDN propio)
 4.  [LOCAL]  Completar vars.yml y vault.yml
 5.  ansible-playbook 1-oracle_users_discovery.yml --ask-vault-pass
 6.  ansible-playbook 2-crossref_oracle_ad.yml --ask-vault-pass
 7.  ansible-playbook 3-spn_report.yml
 8.  ansible-playbook 4-register_spn_keytab.yml --ask-vault-pass
 9.  ansible-playbook 5-check_sqlnet.yml
10.  ansible-playbook 6-configure_sqlnet_kerberos.yml
11.  ansible-playbook 7-configure_krb5_conf.yml
12.  ansible-playbook 8-configure_os_authent_prefix.yml --ask-vault-pass
13.  [MANUAL] ⚠️  Restart de la instancia Oracle (OS_AUTHENT_PREFIX es estático)
14.  ansible-playbook 9-backup_password_hashes.yml --ask-vault-pass
15.  ansible-playbook 10-migrate_users_to_kerberos.yml --ask-vault-pass
16.  ansible-playbook 11-validate_migration.yml --ask-vault-pass
17.  [COEXISTENCIA] Semanas de validación (FALLBACK_AUTHENTICATION=TRUE)
18.  [SI FALLA] ansible-playbook 12-rollback_migration.yml --ask-vault-pass
19.  [FINAL]  Desactivar FALLBACK_AUTHENTICATION en sqlnet.ora
```

### ⚠️ Restart obligatorio (paso 13)

`OS_AUTHENT_PREFIX` es estático y requiere restart para tomar efecto. Sin esto, Oracle antepone `OPS$` a los nombres Kerberos y la autenticación falla.

```sql
sqlplus / as sysdba
SHUTDOWN IMMEDIATE;
STARTUP;
SHOW PARAMETER os_authent_prefix;  -- Debe mostrar '' (vacío)
```

Referencia: https://docs.oracle.com/database/121/DBSEG/asokerb.htm (Step 6B)

## Estructura

```
.
├── ansible.cfg
├── inventory/
│   ├── hosts
│   └── group_vars/all/
│       ├── vars.yml                # BDs Oracle 12c, config AD, Kerberos
│       └── vault.yml               # Credenciales (cifrar con ansible-vault)
├── scripts/
│   └── oracle_query.py
├── tasks/
│   ├── discover_oracle.yml
│   └── load_discovery.yml
├── templates/
│   ├── oracle_report.j2
│   └── crossref_report.j2
├── files/
│   └── ad-ca.pem                   # CA raíz del AD (si se necesita)
├── 1-oracle_users_discovery.yml
├── 2-crossref_oracle_ad.yml
├── 3-spn_report.yml
├── 4-register_spn_keytab.yml
├── 5-check_sqlnet.yml
├── 6-configure_sqlnet_kerberos.yml
├── 7-configure_krb5_conf.yml
├── 8-configure_os_authent_prefix.yml
├── 9-backup_password_hashes.yml
├── 10-migrate_users_to_kerberos.yml
├── 11-validate_migration.yml
├── 12-rollback_migration.yml
├── requirements.yml
└── README.md
```

## Prerequisitos

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install ansible-core oracledb python-ldap
ansible-galaxy collection install -r requirements.yml
```

## Configuración

### vault.yml
```yaml
oracle_user: "<user>"
oracle_password: "<password>"
ad_bind_pw: "<ad_bind_password>"
dc_admin_user: "<domain>\\<admin_user>"
dc_admin_password: "<admin_password>"
kerberos_svc_password: "<kerberos_service_account_password>"
```

### vars.yml
```yaml
oracle_databases:
  - name: "DB12A"
    host: "<ip>"
    port: 1521
    service: "<service_name>"
    oracle_home: "/u01/app/oracle/product/12.1.0/dbhome_1"
    version: "12.1"

kerberos_realm: "LABORATORIO.LOCAL"
kerberos_service: "oracle"
kerberos_service_account: "<sAMAccountName>"

oracle_no_migrate:
  - APP_VENTAS
  - SVC_WEBAPP
```

## Rollback

```bash
# Completo (usuarios + config RHEL + OS_AUTHENT_PREFIX):
ansible-playbook 12-rollback_migration.yml --ask-vault-pass

# Solo usuarios:
ansible-playbook 12-rollback_migration.yml --ask-vault-pass -e "rollback_scope=users_only"

# Un usuario específico:
ansible-playbook 12-rollback_migration.yml --ask-vault-pass \
  -e '{"rollback_scope": "users_only", "rollback_users": ["USR_JPEREZ"]}'
```

## Referencias

- Oracle 12.1 Kerberos: https://docs.oracle.com/database/121/DBSEG/asokerb.htm
- Oracle 11g/12c Kerberos (ASO): https://docs.oracle.com/cd/E11882_01/network.112/e40393/asokerb.htm
- OS_AUTHENT_PREFIX: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/OS_AUTHENT_PREFIX.html
- FALLBACK_AUTHENTICATION: https://docs.oracle.com/database/121/DBSEG/asokerb.htm#DBSEG9741
