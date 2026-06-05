# CIFS / SMB Utilities

Questa cartella contiene script per testare accesso a condivisioni di rete SMB/CIFS, organizzati in Bash e PowerShell.

## Struttura

- `bash/` - script Bash per Linux/Unix.
- `powershell/` - script PowerShell per Windows.

## Come usare

### Bash

```bash
cd base_utils/cifs/bash
bash check_cifs.sh
```

### PowerShell

```powershell
cd .\base_utils\cifs\powershell
.\check_cifs.ps1
```

## Note

- `check_cifs.sh` richiede `smbclient` installato.
- `shares.txt` può contenere commenti con `#`.
- Usa il sotto-README corrispondente (`bash/README.md` o `powershell/README.md`) per i dettagli specifici.
