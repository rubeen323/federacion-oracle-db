# =============================================================================
# 99_cleanup.ps1
# Elimina usuarios y OU creados por el script de aprovisionamiento.
# USAR SOLO SI SE NECESITA RECREAR EL ENTORNO.
#
# Uso:
#   .\99_cleanup.ps1 -Domain "laboratorio.local"
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Domain
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$DomainDN = ($Domain.Split('.') | ForEach-Object { "DC=$_" }) -join ','
$OUFullDN = "OU=Oracle_DB_Users,$DomainDN"

Write-Host "=== Limpieza AD - Oracle DB Users ===" -ForegroundColor Red

# Eliminar usuarios de la OU
$users = Get-ADUser -Filter * -SearchBase $OUFullDN -ErrorAction SilentlyContinue
foreach ($u in $users) {
    Remove-ADUser -Identity $u -Confirm:$false
    Write-Host "[OK] Usuario eliminado: $($u.SamAccountName)" -ForegroundColor Yellow
}

# Eliminar OU (quitar proteccion primero)
$ou = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUFullDN'" -ErrorAction SilentlyContinue
if ($ou) {
    Set-ADOrganizationalUnit -Identity $OUFullDN -ProtectedFromAccidentalDeletion $false
    Remove-ADOrganizationalUnit -Identity $OUFullDN -Confirm:$false
    Write-Host "[OK] OU eliminada: $OUFullDN" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Limpieza completada ===" -ForegroundColor Red
