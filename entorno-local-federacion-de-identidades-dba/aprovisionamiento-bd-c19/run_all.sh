#!/bin/bash
# =============================================================================
# run_all.sh
# Ejecuta todos los scripts de aprovisionamiento en orden
# Uso: ./run_all.sh
# Prerequisitos:
#   - ORACLE_HOME y ORACLE_SID configurados
#   - Acceso como usuario oracle (o con permisos sysdba)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Validar que sqlplus esta disponible
if ! command -v sqlplus &>/dev/null; then
  echo "ERROR: sqlplus no encontrado. Configura ORACLE_HOME y PATH."
  echo "  export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1"
  echo "  export PATH=\$ORACLE_HOME/bin:\$PATH"
  exit 1
fi

# Validar ORACLE_SID
if [ -z "${ORACLE_SID:-}" ]; then
  echo "ERROR: ORACLE_SID no esta definido."
  echo "  export ORACLE_SID=orcl2"
  exit 1
fi

echo "=== Aprovisionamiento BD Oracle 19c - Entorno de pruebas ==="
echo "ORACLE_SID: $ORACLE_SID"
echo ""

SCRIPTS=(
  "01_setup_tablespaces.sql"
  "02_create_roles.sql"
  "03_create_schemas.sql"
  "04_create_tables.sql"
  "05_create_users.sql"
  "06_grant_privileges.sql"
  "07_verify.sql"
)

for script in "${SCRIPTS[@]}"; do
  echo ">>> Ejecutando: $script"
  sqlplus -S / as sysdba @"${SCRIPT_DIR}/${script}"
  echo ""
done

echo "=== Aprovisionamiento completado ==="
