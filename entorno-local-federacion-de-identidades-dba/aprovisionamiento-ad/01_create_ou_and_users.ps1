# =============================================================================
# 01_create_ou_and_users.ps1
# Crea la OU y usuarios en Active Directory para simular el entorno de
# migracion de usuarios Oracle a AD con Kerberos + CMU.
#
# Prerequisitos:
#   - Ejecutar en el Domain Controller (Windows Server 2016)
#   - Ejecutar como Administrador del dominio
#   - El servidor debe estar promovido a Domain Controller
#
# Uso:
#   .\01_create_ou_and_users.ps1 -Domain "laboratorio.local"
#
# Referencia:
#   https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-adorganizationalunit
#   https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Domain
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

# --- Derivar DN base del dominio ---
$DomainDN = ($Domain.Split('.') | ForEach-Object { "DC=$_" }) -join ','

# --- Configuracion ---
$OUName        = "Oracle_DB_Users"
$OUPath        = $DomainDN
$OUFullDN      = "OU=$OUName,$DomainDN"
$DefaultPass   = ConvertTo-SecureString "TempPass2026#!" -AsPlainText -Force

# Usuarios a migrar (sAMAccountName coincide exactamente con el username de Oracle)
$UsersToMigrate = @(
    @{ Sam = "USR_JPEREZ";      GivenName = "Juan";    Surname = "Perez";      Display = "Juan Perez";       Desc = "Analista de ventas" }
    @{ Sam = "USR_MLOPEZ";      GivenName = "Maria";   Surname = "Lopez";      Display = "Maria Lopez";      Desc = "Ejecutivo de ventas" }
    @{ Sam = "USR_AGARCIA";     GivenName = "Andres";  Surname = "Garcia";     Display = "Andres Garcia";    Desc = "Jefe de operaciones" }
    @{ Sam = "USR_CRODRIGUEZ";  GivenName = "Camila";  Surname = "Rodriguez";  Display = "Camila Rodriguez"; Desc = "Analista BI" }
    @{ Sam = "USR_ETL_NIGHTLY"; GivenName = "ETL";     Surname = "Nightly";    Display = "ETL Nightly";      Desc = "Operador ETL" }
    @{ Sam = "USR_DBA_APP";     GivenName = "DBA";     Surname = "Aplicativo"; Display = "DBA Aplicativo";   Desc = "DBA aplicativo" }
)

# =============================================================================
# 1. Crear OU
# =============================================================================
Write-Host "=== Aprovisionamiento AD para migracion Oracle ===" -ForegroundColor Cyan
Write-Host "Dominio : $Domain"
Write-Host "DN Base : $DomainDN"
Write-Host "OU      : $OUFullDN"
Write-Host ""

if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -SearchBase $DomainDN -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $OUName -Path $OUPath `
        -Description "Usuarios de bases de datos Oracle para federacion de identidades" `
        -ProtectedFromAccidentalDeletion $true
    Write-Host "[OK] OU creada: $OUFullDN" -ForegroundColor Green
} else {
    Write-Host "[SKIP] OU ya existe: $OUFullDN" -ForegroundColor Yellow
}

# =============================================================================
# 2. Crear usuarios en la OU
# =============================================================================
Write-Host ""
Write-Host "--- Creando usuarios ---"

foreach ($u in $UsersToMigrate) {
    $upn = "$($u.Sam)@$Domain"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name $u.Display `
            -SamAccountName $u.Sam `
            -UserPrincipalName $upn `
            -GivenName $u.GivenName `
            -Surname $u.Surname `
            -DisplayName $u.Display `
            -Description $u.Desc `
            -Path $OUFullDN `
            -AccountPassword $DefaultPass `
            -Enabled $true `
            -PasswordNeverExpires $false `
            -ChangePasswordAtLogon $false
        Write-Host "[OK] Usuario creado: $($u.Sam) -> $upn" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] Usuario ya existe: $($u.Sam)" -ForegroundColor Yellow
    }
}

# =============================================================================
# 3. Verificacion
# =============================================================================
Write-Host ""
Write-Host "=== Verificacion ===" -ForegroundColor Cyan
Get-ADUser -Filter * -SearchBase $OUFullDN -Properties DisplayName, Description |
    Format-Table SamAccountName, DisplayName, Description, Enabled -AutoSize

Write-Host ""
Write-Host "=== Aprovisionamiento AD completado ===" -ForegroundColor Cyan
Write-Host "Total usuarios en OU: $((Get-ADUser -Filter * -SearchBase $OUFullDN).Count)"
