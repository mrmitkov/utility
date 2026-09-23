# Katello Satellite

Questa cartella contiene script utili per creare e sincronizzare repository di distribuzioni Linux all'interno di Katello/Satellite.

## Contenuto

- `create_ubuntu_repos.sh`  Script per creare i repository di Ubuntu per le release supportate, con la struttura dei repo Debian/Ubuntu.
- `create_rocky_repos.sh`  Script per creare i repository di Rocky Linux 8.10 e 9.8, basati su `https://download.rockylinux.org/pub/rocky`.

## Requisiti

- Client Katello/Satellite con `hammer` disponibile
- Accesso autorizzato all'organizzazione Katello
- Parametro `ORG` impostato correttamente nello script
- Connessione ai mirror ufficiali delle distribuzioni

## Esempio di utilizzo

```bash
chmod +x create_rocky_repos.sh
./create_rocky_repos.sh
```

Per Ubuntu:

```bash
chmod +x create_ubuntu_repos.sh
./create_ubuntu_repos.sh
```

## Note

- Gli script impostano il nome del prodotto e i repository in modo semplice da adattare alla propria installazione.
- È possibile modificare `ORG`, `PRODUCT`, `ARCH` e i path dei repository in base all'ambiente.
- I comandi di sincronizzazione vengono eseguiti in modalità async per evitare di bloccare la sessione.

## URL di base usati

- Ubuntu: `http://archive.ubuntu.com/ubuntu`
- Rocky: `https://download.rockylinux.org/pub/rocky`
