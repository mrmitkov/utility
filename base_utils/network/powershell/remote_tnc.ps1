# File ini
$iniPath = Join-Path $PSScriptRoot "hosts.ini"

# Server target e porta
Write-Host "=== REMOTE TNC CHECK ===" -ForegroundColor Cyan
Write-Host "This script checks connectivity from multiple hosts to a target server and port using WinRM." -ForegroundColor Gray
Write-Host "Make sure the hosts.ini file is properly configured with domains and hostnames." -ForegroundColor Gray 
Write-Host "Example hosts.ini format:" -ForegroundColor Gray
Write-Host "[DOMAIN1]" -ForegroundColor Yellow
Write-Host "host1.domain1.com" -ForegroundColor Yellow
Write-Host "host2.domain1.com" -ForegroundColor Yellow
Write-Host "[DOMAIN2]" -ForegroundColor Yellow
Write-Host "host1.domain2.com" -ForegroundColor Yellow
Write-Host "host2.domain2.com" -ForegroundColor Yellow

Write-Host "`nPlease enter the target server and port to check connectivity against." -ForegroundColor Gray
$tgs = Read-Host "Target Server"
$port = Read-Host "Port"

# Credenziali
Write-Host "`nEnter credentials to use for WinRM connections." -ForegroundColor Gray
$domain = Read-Host "Domain"
$user = Read-Host "Username"
$pass = Read-Host "Password" -AsSecureString

$cred = New-Object System.Management.Automation.PSCredential("$domain\$user", $pass)

# Parsing INI
$ini = @{}
$currentSection = ""

Get-Content $iniPath | ForEach-Object {
    $line = $_.Trim()

    if ($line -match "^\[(.+)\]$") {
        $currentSection = $matches[1]
        $ini[$currentSection] = @()
    }
    elseif ($line -and $currentSection) {
        $ini[$currentSection] += $line
    }
}

# Loop domini + host

if ($ini.ContainsKey($domain)) {

    Write-Host "`n=== DOMINIO: $domain ===" -ForegroundColor Cyan

    foreach ($vmh in $ini[$domain]) {

        Write-Host "Checking $vmh ..." -ForegroundColor Yellow

        # 1. Verifica DNS
        if (-not (Resolve-DnsName $vmh -ErrorAction SilentlyContinue)) {
            Write-Host "$vmh -> NON RISOLTO DNS" -ForegroundColor DarkGray
            continue
        }

        # 2. Ping veloce
        if (-not (Test-Connection -ComputerName $vmh -Count 1 -Quiet)) {
            Write-Host "$vmh -> OFFLINE" -ForegroundColor DarkGray
            continue
        }

        # 3. WinRM reachable
        if (-not (Test-NetConnection -ComputerName $vmh -Port 5985 -InformationLevel Quiet)) {
            Write-Host "$vmh -> WINRM NON DISPONIBILE" -ForegroundColor DarkGray
            continue
        }

        # 4. Solo ora esegui Invoke-Command
        try {
            $result = Invoke-Command -ComputerName $vmh -Credential $cred -ScriptBlock {
                param($tgs, $port)
                Test-NetConnection -ComputerName $tgs -Port $port
            } -ArgumentList $tgs, $port

            if ($result.TcpTestSucceeded) {
                Write-Host "$vmh vs $tgs on Port $port -> OK" -ForegroundColor Green
            } else {
                Write-Host "$vmh vs $tgs on Port $port -> FAIL" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "$vmh -> ERROR: $_" -ForegroundColor Magenta
        }
    }

} else {
    Write-Host "Dominio $domain non trovato nel file INI" -ForegroundColor Red
}