# PowerShell Network Utilities

Script PowerShell per verifiche di connettività remota.

## Script disponibili

- `remote_tnc.ps1` - controlla DNS, ping e raggiungibilità WinRM verso host remoti.

## Esempio

```powershell
.\remote_tnc.ps1
```

## Note

- Lo script si aspetta un file `hosts.ini` nella stessa cartella.
- Le credenziali vengono richieste a runtime.