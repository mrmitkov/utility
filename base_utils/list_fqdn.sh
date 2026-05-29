#!/bin/bash
# Funzione di help

function show_help {
    echo "Uso: $0 -s <file_sorgente> -d <file_destinazione> [-f | -a]"
    echo ""
    echo "Opzioni:"
    echo "  -s    File contenente la lista da elaborare"
    echo "  -d    File di output con i FQDN"
    echo "  -f    Forza la sovrascrittura del file di destinazione"
    echo "  -a    Aggiunge in coda al file di destinazione"
    echo "  -h    Mostra questo messaggio di aiuto"
    exit 0
}

# Parsing degli argomenti
FORCE_OVERWRITE=false
APPEND_MODE=false

while getopts "s:d:hHfa" opt; do
    case $opt in
        s) SOURCE_FILE="$OPTARG" ;;
        d) DEST_FILE="$OPTARG" ;;
        f) FORCE_OVERWRITE=true ;;
        a) APPEND_MODE=true ;;
        h|H) show_help ;;
        *) show_help ;;
    esac
done
# Controllo che i file siano stati specificati
if [[ -z "$SOURCE_FILE" || -z "$DEST_FILE" ]]; then
    echo "Errore: file sorgente o destinazione non specificati."
    show_help
fi

# Controllo esistenza file destinazione
if [[ -f "$DEST_FILE" && "$FORCE_OVERWRITE" = false && "$APPEND_MODE" = false ]]; then
    echo "Errore: il file '$DEST_FILE' esiste già."
    echo "Usa -f per sovrascrivere o -a per aggiungere in coda."
    exit 1
fi

# Preparazione file destinazione
if [[ "$FORCE_OVERWRITE" = true ]]; then
    > "$DEST_FILE"
fi

# Elaborazione
cat "$SOURCE_FILE" | nslookup | grep Name | awk '{print $2}' | tr '[:upper:]' '[:lower:]' >> "$DEST_FILE"

echo "Operazione completata. Output scritto in '$DEST_FILE'."
