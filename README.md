# Utility Scripts Repository

Repository contenente utility in shell, PowerShell e Java per supportare attività di infrastruttura, rete, sicurezza, gestione container e test di connettività a database.

## Struttura delle directory

- `base_utils/`
  - `cifs/` - script per verificare condivisioni SMB/CIFS e gestire elenchi di share.
  - `network/` - utility per test di rete, ping, DNS e controllo di servizi remoti.
  - `misc/` - script generici e snippet utili per funzioni bash.
- `cleanup/` - script per la pulizia automatica di log e mailbox, con configurazione `logrotate`.
- `clone_utils/` - script per clonare file in base a data di modifica.
- `container_utils/` - script per controllo runtime, healthcheck e diagnosi container.
- `katello_satellite/` - utility per la creazione di repository per sistemi Rocky e Ubuntu in ambienti Katello/Satellite.
- `oracle_db/` - test Java JDBC per verificare la connessione a Oracle tramite `SERVICE_NAME` e `SID`.

## Uso

Apri la cartella della funzionalità che ti interessa e leggi il README locale per trovare le istruzioni specifiche e i parametri richiesti.

## Esempi di utilizzo

- Controllo condivisioni CIFS: leggere il README di `base_utils/cifs`
- Test di connessione remota: usare gli script in `base_utils/network`
- Pulizia log e mailbox: consultare `cleanup/`
- Test Oracle JDBC: usare la cartella `oracle_db/` e leggere il relativo README

## Note

Il repository è organizzato per area funzionale per rendere più semplice individuare, mantenere e riutilizzare gli script correlati.
