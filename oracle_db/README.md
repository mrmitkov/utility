<style>
a {
    text-decoration: none;
    color: #464feb;
}
tr th, tr td {
    border: 1px solid #e6e6e6;
}
tr th {
    background-color: #f5f5f5;
}
</style>

# Test Oracle JDBC

Questa cartella contiene due test Java per verificare la connettività a un database Oracle tramite JDBC.

I file principali sono:

- `test_oracle_service.java` -> usa un `SERVICE_NAME`
- `test_oracle_sid.java` -> usa un `SID`

Entrambi cercano di caricare il driver Oracle, aprire una connessione e verificare la versione del database.

---

## 1. Prerequisiti

Prima di eseguire i test è necessario avere:

- Java JDK installato
- il driver Oracle JDBC disponibile localmente, ad esempio:
  - `jdbc*.jar` oppure il file specifico del driver Oracle presente nel sistema, come `ojdbc8.jar` / `ojdbc11.jar`
- le credenziali corrette per l’istanza Oracle
- l’URL JDBC corretto (`SERVICE_NAME` o `SID`)

> In entrambi i sorgenti, aggiornare i valori di `url`, `user` e `password` prima dell’esecuzione.

---

## 2. Compilazione

Esempio generico di compilazione con Oracle JDBC:

```bash
cd /tmp
javac -cp /path/to/ojdbc*.jar test_oracle_service.java
```

Oppure, se il file è noto e specifico:

```bash
javac -cp /path/to/your/ojdbc11.jar test_oracle_service.java
```

Verifica che il file `.class` sia stato creato:

```bash
ls -l test_oracle_service.class
```

---

## 3. Esecuzione

```bash
java \
  -cp .:/path/to/ojdbc*.jar \
  test_oracle_service
```

Se il jar è un file specifico, usare invece:

```bash
java \
  -cp .:/path/to/your/ojdbc11.jar \
  test_oracle_service
```

Se il test è stato compilato in un’altra directory, assicurarsi che il percorso della classe sia corretto e che il jar JDBC sia incluso nel classpath.

---

## 4. Output atteso

Su un database Oracle 19c, un risultato corretto è simile a questo:

```text
Loading Oracle Driver...
Connecting...
Connection OK
Database : Oracle
Version  : Oracle Database 19c Enterprise Edition ...

INSTANCE=PROD19
VERSION=19.23.0.0.0

Test SUCCESS
```

Questo indica che:

- il driver JDBC è stato caricato correttamente
- la connessione al listener Oracle è andata a buon fine
- la connessione al database è stata stabilita
- la query su `v$instance` o `USERENV` è stata eseguita correttamente

---

## 5. Errori significativi e loro significato

### Driver trovato ma autenticazione incompatibile

```text
ORA-28040:
No matching authentication protocol
```

Il driver è troppo vecchio per la policy di autenticazione del database Oracle 19c.

---

### Credenziali errate

```text
ORA-01017:
invalid username/password
```

La rete e il driver funzionano, ma le credenziali inserite non sono corrette.

---

### Listener raggiungibile ma service errato

```text
ORA-12514
```

oppure

```text
ORA-12505
```

Questo segnala un problema nel `SERVICE_NAME` o nel `SID` indicato nell’URL JDBC.

---

### Problemi TLS

```text
ORA-29024
```

oppure

```text
ORA-28860
```

Questi errori possono verificarsi quando il DBA ha imposto `TCPS` o cifratura TLS per la connessione.

---

## 6. Suggerimenti pratici

- Verificare sempre che il `url` sia corretto e che il `SERVICE_NAME` / `SID` esista davvero.
- Controllare che la versione del driver Oracle sia compatibile con la versione del database.
- Verificare che il listener Oracle sia raggiungibile dalla macchina che esegue il test.
- Controllare eventuali politiche di sicurezza come TLS o TCPS.
- Se necessario, utilizzare un file di log o il debug JDBC per analizzare il problema in modo più dettagliato.

---

## 7. Esempio di URL JDBC

```text
jdbc:oracle:thin:@//HOST:1521/SERVICE_NAME
```

oppure

```text
jdbc:oracle:thin:@HOST:1521:SID
```

Il formato corretto dipende dalla configurazione del database e dal tipo di connessione desiderata.
