# container_utils

Questo directory contiene script e configurazioni utili per gestire la salute di
container Docker/Podman e operazioni correlate.

## Script principali

### `container-runtime.sh`

Rileva il runtime dei container disponibile sul sistema (`docker` o `podman`).
Puoi eseguirlo direttamente per sapere quale comando usare:

```sh
$ ./container-runtime.sh
docker
```

Lo script è pensato anche per essere "sourced" in altri script quando serve il
comando appropriato al runtime.

### `container-healthcheck.sh`

Esegue un controllo sulle risorse (CPU e RAM) di un container specificato e, in
caso vengano superate le soglie impostate, riavvia il container.

#### Sintassi

```sh
./container-healthcheck.sh <nome_container> [-lmcpu <percent>] \
    [-lmram <MB|MiB|GB|GiB|percent>]
```

#### Opzioni

- `-lmcpu`, `--limit-max-cpu`: limite CPU in percentuale (es. `70` o `70%`).
- `-lmram`, `--limit-max-ram`: limite RAM. Accetta valori assoluti (es. `500`,
  `512MiB`, `1.5GiB`) oppure percentuali (`75%`).
- `-h`, `--help`: mostra questa guida.

#### Esempi

```sh
# controllo solo CPU
./container-healthcheck.sh nginx -lmcpu 70

# limite RAM assoluto + percentuale CPU
./container-healthcheck.sh myapp -lmcpu 50 -lmram 1GiB

# controllo percentuale di RAM sul limite configurato del container
./container-healthcheck.sh myapp -lmram 80%
```

#### Integrazione cron/logrotate

Un possibile job cron per controllare periodicamente un container:

```cron
*/5 * * * * cd /path/to/container_utils && ./container-healthcheck.sh myapp \
    -lmcpu 80 -lmram 1GiB >>/var/log/container-healthcheck.log 2>&1
```

Il file `logrotate_helthcheck` contiene una semplice configurazione per far
ruotare il log generato da questi job:

```text
/var/log/container-healthcheck.log {
    rotate 12
    monthly
    compress
    missingok
    notifempty
    create 664 root adm
}
```

Copia o includi questo blocco nelle impostazioni di `logrotate` del tuo sistema
per mantenere i file di log sotto controllo.

## Note generali

- Gli script sono scritti in bash "cron-safe" e non dipendono dalle variabili
di ambiente dell'utente.
- Prima di usarli, assicurati che `docker` o `podman` siano installati ed
  accessibili nel `PATH`.
- Puoi estendere `container-healthcheck.sh` aggiungendo ulteriori controlli
  (es. I/O, rete) oppure integrare un meccanismo di *hysteresis* per evitare
  riavvii troppo frequenti.

---

Questa cartella è pensata per essere inclusa in strumenti di automazione o
repository condivisi; sentiti libero di adattare gli script alle tue esigenze.