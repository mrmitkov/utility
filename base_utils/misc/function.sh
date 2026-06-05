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
functions=(function1 function2 function3)

# Creazione dell'interfaccia con selezione a spunta
selected_functions=()
while true; do
  echo "Seleziona le funzioni da eseguire (scrivi 'esegui' per avviare le funzioni selezionate):"
  for i in "${!functions[@]}"; do
    if [[ "${selected_functions[*]}" =~ "${functions[$i]}" ]]; then
      echo -n "[x] "
    else
      echo -n "[ ] "
    fi
    echo "${functions[$i]}"
  done
  read -p "Seleziona una funzione (o digita 'esegui'): " choice
  if [[ "$choice" == "esegui" ]]; then
    break
  elif [[ "${functions[*]}" =~ "$choice" ]]; then
    if [[ "${selected_functions[*]}" =~ "$choice" ]]; then
      selected_functions=(${selected_functions[@]/$choice})
    else
      selected_functions+=($choice)
    fi
  else
    echo "Scelta non valida"
  fi
done

# Esecuzione delle funzioni selezionate
echo "Esecuzione delle seguenti funzioni:"
for func in "${selected_functions[@]}"; do
  echo "- $func"
  $func
done
