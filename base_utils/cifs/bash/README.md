# CIFS Bash Utilities

Questa cartella contiene gli script Bash per testare accesso a condivisioni SMB/CIFS.

## Script disponibili

- `check_cifs.sh` - verifica l'accesso a share SMB/CIFS usando `smbclient`.

## File di supporto

- `shares.txt` - lista di share da usare con `check_cifs.sh`.

## Uso

```bash
cd base_utils/cifs/bash
bash check_cifs.sh
```

## Note

- `check_cifs.sh` richiede `smbclient` installato.
- `shares.txt` può contenere commenti con `#`.
