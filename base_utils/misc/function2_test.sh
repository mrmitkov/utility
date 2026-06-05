#!/bin/bash
# Definizione delle funzioni
function function1() {
  echo "Funzione 1"
}

function function2() {
  echo "Funzione 2"
}

function function3() {
  echo "Funzione 3"
}

# Array delle funzioni
functions=(function1 "Descrizione funzione 1" off
           function2 "Descrizione funzione 2" off
           function3 "Descrizione funzione 3" off)

# Creazione del popup con la selezione a spunta
selected_functions=$(dialog --checklist "Seleziona le funzioni da eseguire" 0 0 0 \
  "${functions[@]}" 2>&1 >/dev/tty)

# Esecuzione delle funzioni selezionate
echo "Esecuzione delle seguenti funzioni:"
for func in $selected_functions; do
  echo "- $func"
  $func
done
