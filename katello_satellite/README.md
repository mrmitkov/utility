# Katello Satellite

Questa cartella contiene script utili per creare e sincronizzare repository di distribuzioni Linux all'interno di Katello/Satellite.

## Contenuto

- `create_ubuntu_repos.sh`  Script per creare i repository di Ubuntu per le release supportate, con la struttura dei repo Debian/Ubuntu.
- `create_rocky_repos.sh`  Script per creare i repository di Rocky Linux 8.10 e 9.8, basati su `https://download.rockylinux.org/pub/rocky`.
- `crea_sm_repos.sh`  Crea il Product `ATIX Subscription Manager` con repository Debian, Ubuntu e SLES ospitati su `https://oss.atix.de`.

## Requisiti

- Client Katello/Satellite con `hammer` disponibile
- Accesso autorizzato all'organizzazione Katello
- Parametro `ORG` impostato correttamente nello script
- Connessione ai repository sorgente delle distribuzioni

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

Per i repository ATIX di Subscription Manager:

```bash
chmod +x crea_sm_repos.sh
./crea_sm_repos.sh
```

## Modalità di creazione

All'avvio, ciascuno dei tre script propone tre modalità:

- `T`: crea tutti i repository senza ulteriori conferme.
- `S`: chiede conferma (`y/n` oppure `yes/no`) per ciascun repository.
- `A`: annulla prima di creare il Product.

In modalità `S`, i repository rifiutati vengono saltati. La sincronizzazione riguarda solo i repository creati durante l'esecuzione, uno per comando.

## Tipi e policy

Il Product Subscription Manager comprende Debian 11/12/13, Ubuntu 20.04/22.04/24.04/26.04 e SLES 12 SP5, 15 SP5/SP6/SP7 e 16.0. I repository APT usano l'architettura `amd64`; quelli SLES sono di tipo RPM (`yum`). Tutti e tre gli script usano download `On Demand` e mirroring `Content Only`.

## Note

- Gli script impostano il nome del prodotto e i repository in modo semplice da adattare alla propria installazione.
- È possibile modificare `ORG`, `PRODUCT`, `ARCH` e i path dei repository in base all'ambiente. In `crea_sm_repos.sh`, l'organizzazione è `ORG1` e il Product è `ATIX Subscription Manager`.
- I comandi di sincronizzazione vengono eseguiti in modalità async per evitare di bloccare la sessione.
- Gli script non sono idempotenti: se un repository esiste già, il comando di creazione può fallire e interrompere l'esecuzione. Verifica i repository presenti in Satellite prima di rilanciarli dopo una creazione parziale.

## URL di base usati

- Ubuntu: `http://archive.ubuntu.com/ubuntu`
- Rocky: `https://download.rockylinux.org/pub/rocky`
- Subscription Manager: `https://oss.atix.de`
