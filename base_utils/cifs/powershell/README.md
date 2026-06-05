# CIFS PowerShell Utilities

Questa cartella contiene gli script PowerShell per testare accesso a condivisioni SMB/CIFS.

## Script disponibili

- `check_cifs.ps1` - verifica l'accesso a share SMB/CIFS su Windows usando PowerShell.

## File di supporto

- `shares.txt` - elenco di share SMB/CIFS da testare.

## Uso

```powershell
cd .\base_utils\cifs\powershell
.\check_cifs.ps1
```

## Note

- Lo script richiede credenziali valido per accedere alle condivisioni SMB/CIFS.
- `shares.txt` può contenere commenti con `#`.
