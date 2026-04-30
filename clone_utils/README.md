# clone_utils

Questo directory contiene script utili per clonare e gestire file in base a date
e metadati temporali.

## Script principali

### `clone_dates.sh`

Script che copia file da una directory sorgente a una directory di destinazione,
organizzando i file per hostname e mese di modifica.

#### Descrizione

Lo script:
1. Esegue una scansione ricorsiva di file nella directory sorgente
2. Seleziona i file modificati tra una data di inizio e oggi
3. Copia i file nella directory di destinazione organizzandoli per:
   - Hostname del sistema
   - Mese di modifica (YYYY-MM)
4. Riporta i file copiati con successo e quelli che hanno generato errori

#### Configurazione

Le seguenti variabili possono essere personalizzate direttamente nel file script:

- `SOURCE_DIR`: directory sorgente dove cercare i file (default: `/photos/temp`)
- `DEST_DIR`: directory di destinazione dove copiare i file (default: `/photos/clone_dates`)
- `START_DATE`: data di inizio per la selezione (formato YYYY-MM-DD, default: `2024-10-01`)

#### Sintassi

```sh
./clone_dates.sh
```

Lo script non richiede parametri sulla riga di comando.

#### Esempio di struttura output

```
/photos/clone_dates/
├── hostname1/
│   ├── 2024-10/
│   │   ├── file1.jpg
│   │   └── file2.jpg
│   └── 2024-11/
│       └── file3.jpg
└── hostname2/
    └── 2024-10/
        └── file4.jpg
```

#### Output

Lo script fornisce un output progressivo durante l'esecuzione:

- Numero totale di file trovati
- Barra di progresso con conteggio e percentuale
- Lista dei file con errori (se presenti)
- Messaggio di completamento con ✅ o ⚠️

#### Esempio di esecuzione

```sh
$ ./clone_dates.sh
Scanning files...
Found 150 file(s) to process.
Copying [150/150] 100%...
✅ All files copied successfully.
```

#### Utilizzo di rsync

Lo script utilizza `rsync` per la copia dei file. Per funzionare correttamente,
assicurati che:

- `rsync` sia installato sul sistema
- Le directory sorgente e destinazione abbiano permessi adeguati
- Lo script sia eseguibile (`chmod +x clone_dates.sh`)
