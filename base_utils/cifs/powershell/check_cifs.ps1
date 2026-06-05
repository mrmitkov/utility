$shares = Get-Content ".\shares.txt"

# Input credenziali
$domain = Read-Host "Domain"
$user = Read-Host "Username"
$pass = Read-Host "Password" -AsSecureString

$cred = New-Object System.Management.Automation.PSCredential("$domain\$user", $pass)

foreach ($share in $shares) {

    if ([string]::IsNullOrWhiteSpace($share) -or $share.StartsWith("#")) {
        continue
    }

    Write-Host -NoNewline "Testing $share ... "

    # nome random per evitare collisioni
    $driveName = "T" + (Get-Random -Maximum 9999)

    try {
        New-PSDrive -Name $driveName -PSProvider FileSystem -Root $share -Credential $cred -ErrorAction Stop | Out-Null

        # test accesso (simile a ls)
        Get-ChildItem "$($driveName):\" -ErrorAction Stop | Out-Null

        Write-Host "✅ OK"

        Remove-PSDrive -Name $driveName -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "❌ FAIL"
    }
}
