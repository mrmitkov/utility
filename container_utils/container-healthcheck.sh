#!/usr/bin/env bash
set -o pipefail

# --- Locale & PATH fix (cron-safe) ---
export LC_ALL=C
export LC_NUMERIC=C
export LANG=C
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# USAGE:
#   ./container-healthcheck.sh <container_name> [-lmcpu <percent>] [-lmram <MB|MiB|GB|GiB|percent>]
#
# ESEMPI:
#   ./container-healthcheck.sh nginx -lmcpu 70
#   ./container-healthcheck.sh nginx -lmcpu 70% -lmram 1.5GiB
#   ./container-healthcheck.sh nginx -lmram 75%
#   ./container-healthcheck.sh nginx -lmram 600MB

usage() {
  cat <<'EOF'
Usage:
  container-healthcheck.sh <container_name> [-lmcpu <percent>] [-lmram <MB|MiB|GB|GiB|percent>]

Options:
  -lmcpu, --limit-max-cpu  Limite CPU in percentuale (es. 70 o 70%)
  -lmram, --limit-max-ram  Limite RAM. Accetta:
                           - numero semplice = MB (es. 500)
                           - unità: MiB, MB, GiB, GB (es. 512MiB, 1.5GiB)
                           - percentuale: (es. 70%)

Examples:
  ./container-healthcheck.sh myapp -lmcpu 70 -lmram 1GiB
  ./container-healthcheck.sh myapp -lmram 75%          # 75% del limite container
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

CONTAINER_NAME="$1"
shift

CPU_LIMIT_PCT=""
RAM_LIMIT_MODE=""   # "abs_mb" | "percent"
RAM_LIMIT_VALUE=""  # numerico

# --- Helpers ---
trim() { awk '{$1=$1;print}' <<<"$*"; }

is_number() { awk -v x="$1" 'BEGIN{ if (x ~ /^-?[0-9]+(\.[0-9]+)?$/) exit 0; else exit 1 }'; }

float_gt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'; }
float_ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }
float_div() { awk -v a="$1" -v b="$2" 'BEGIN{ if (b==0) { print "NaN" } else { printf "%.6f", a/b } }'; }
float_mul() { awk -v a="$1" -v b="$2" 'BEGIN{ printf "%.6f", a*b }'; }

# Stampa sicura con formattazione numerica
fmt2() {
  local v="$1"
  if is_number "$v"; then
    printf "%.2f" "$v"
  else
    printf "%s" "$v"
  fi
}

# Converte stringhe tipo "824KiB", "1.5GiB", "512MB" in MB
# Supporta: KiB, KB, MiB, MB, GiB, GB (case-insensitive).
to_mb() {
  local in="$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)"
  local val unit
  val="$(echo "$in" | sed -E 's/[^0-9.]+//g')"
  unit="$(echo "$in" | sed -E 's/[0-9.\s]+//g')"

  if ! is_number "$val"; then
    echo "NaN"; return
  fi

  case "$unit" in
    kib) awk -v v="$val" 'BEGIN{ printf "%.6f", v/1024*1.048576 }' ;;   # 1 KiB = 0.0009765625 MiB = 0.001048576 MB
    kb|k) awk -v v="$val" 'BEGIN{ printf "%.6f", v/1000 }' ;;           # 1 kB = 0.001 MB
    mib) awk -v v="$val" 'BEGIN{ printf "%.6f", v*1.048576 }' ;;        # 1 MiB = 1.048576 MB
    mb|"" ) awk -v v="$val" 'BEGIN{ printf "%.6f", v }' ;;              # default: MB
    gib) awk -v v="$val" 'BEGIN{ printf "%.6f", v*1073.741824 }' ;;     # 1 GiB = 1073.741824 MB
    gb|g) awk -v v="$val" 'BEGIN{ printf "%.6f", v*1000 }' ;;           # 1 GB = 1000 MB
    *) echo "NaN" ;;
  esac
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage; exit 0;;
    -lmcpu|--limit-max-cpu)
      if [[ -z "${2:-}" ]]; then echo "Errore: manca il valore per $1"; exit 1; fi
      raw="$2"; shift 2
      raw="${raw%%%}"
      if ! is_number "$raw"; then
        echo "Errore: valore CPU non valido: $raw"; exit 1
      fi
      if ! awk -v v="$raw" 'BEGIN{exit (v>=0 && v<=100)?0:1}'; then
        echo "Errore: CPU deve essere tra 0 e 100"; exit 1
      fi
      CPU_LIMIT_PCT="$raw"
      ;;
    -lmram|--limit-max-ram)
      if [[ -z "${2:-}" ]]; then echo "Errore: manca il valore per $1"; exit 1; fi
      raw="$2"; shift 2
      raw_trimmed="$(trim "$raw")"
      if [[ "$raw_trimmed" =~ %$ ]]; then
        val="${raw_trimmed%%%}"
        if ! is_number "$val"; then
          echo "Errore: percentuale RAM non valida: $raw_trimmed"; exit 1
        fi
        if ! awk -v v="$val" 'BEGIN{exit (v>0 && v<=100)?0:1}'; then
          echo "Errore: percentuale RAM deve essere tra 0 e 100"; exit 1
        fi
        RAM_LIMIT_MODE="percent"
        RAM_LIMIT_VALUE="$val"
      else
        mb="$(to_mb "$raw_trimmed")"
        if [[ "$mb" == "NaN" ]]; then
          echo "Errore: formato RAM non riconosciuto: $raw_trimmed (usa MB, MiB, GB, GiB o %)"
          exit 1
        fi
        RAM_LIMIT_MODE="abs_mb"
        RAM_LIMIT_VALUE="$mb"
      fi
      ;;
    *)
      echo "Argomento sconosciuto: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$CONTAINER_NAME" ]]; then
  usage; exit 1
fi

# --- Runtime detection ---
RUNTIME=$(./scripts/container-runtime.sh)
if [[ $? -ne 0 || -z "$RUNTIME" || "$RUNTIME" == Error* ]]; then
  echo "Errore: impossibile determinare il container runtime (docker/podman)."
  exit 1
fi

# --- Stats ---
if [[ "$RUNTIME" == "podman" ]]; then
  STATS=$($RUNTIME stats --no-stream --format '{{.CPU}}|{{.MemUsage}}' "$CONTAINER_NAME" 2>/dev/null)
else
  STATS=$($RUNTIME stats --no-stream --format '{{.CPUPerc}}|{{.MemUsage}}' "$CONTAINER_NAME" 2>/dev/null)
fi

if [[ -z "$STATS" ]]; then
  echo "Errore: container '$CONTAINER_NAME' non trovato o nessuna statistica disponibile."
  exit 1
fi

IFS='|' read -r CPU_RAW MEMUSAGE_RAW <<< "$STATS"

CPU_VAL="$(echo "$CPU_RAW" | tr -d ' %' | xargs)"

# Esempio MEMUSAGE_RAW: "824KiB / 1.944GiB" oppure "412MiB / 0B"
MEM_USED_STR="$(echo "$MEMUSAGE_RAW"  | awk -F'/' '{print $1}' | xargs)"
MEM_LIMIT_STR="$(echo "$MEMUSAGE_RAW" | awk -F'/' '{print $2}' | xargs)"

MEM_USED_MB="$(to_mb "$MEM_USED_STR")"
MEM_LIMIT_MB=""
if [[ -n "$MEM_LIMIT_STR" ]]; then
  tmp="$(to_mb "$MEM_LIMIT_STR")"
  [[ "$tmp" != "NaN" ]] && MEM_LIMIT_MB="$tmp"
fi

if ! is_number "$CPU_VAL"; then
  echo "Attenzione: valore CPU non numerico ottenuto: '$CPU_RAW'"
  CPU_VAL="0"
fi

if [[ "$MEM_USED_MB" == "NaN" ]]; then
  echo "Errore nel parsing della RAM usata: '$MEM_USED_STR' (da: '$MEMUSAGE_RAW')"
  exit 1
fi

MEM_PCT_USED=""
if [[ -n "$MEM_LIMIT_MB" ]] && is_number "$MEM_LIMIT_MB" && awk -v l="$MEM_LIMIT_MB" 'BEGIN{exit (l>0)?0:1}'; then
  ratio="$(float_div "$MEM_USED_MB" "$MEM_LIMIT_MB")"
  MEM_PCT_USED="$(float_mul "$ratio" "100")"
fi

echo "############### START ###############"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Container: $CONTAINER_NAME"
echo "CPU attuale: ${CPU_VAL}%"
printf "RAM attuale: "
fmt2 "$MEM_USED_MB"
if [[ -n "$MEM_LIMIT_MB" ]]; then
  printf " MB / Limite: "
  fmt2 "$MEM_LIMIT_MB"
  printf " MB"
else
  printf " MB"
fi
printf "\n"

if [[ -n "$MEM_PCT_USED" ]]; then
  printf "RAM usata: "
  fmt2 "$MEM_PCT_USED"
  printf "%% del limite\n"
fi

RESTART=0

# --- CPU CHECK ---
if [[ -n "$CPU_LIMIT_PCT" ]]; then
  echo "Limite CPU: ${CPU_LIMIT_PCT}%"
  if float_gt "$CPU_VAL" "$CPU_LIMIT_PCT"; then
    echo "⚠️  CPU sopra la soglia!"
    RESTART=1
  fi
else
  echo "CPU check disabilitato."
fi

# --- RAM CHECK ---
if [[ -n "$RAM_LIMIT_MODE" ]]; then
  if [[ "$RAM_LIMIT_MODE" == "abs_mb" ]]; then
    printf "Limite RAM (assoluto): "
    fmt2 "$RAM_LIMIT_VALUE"
    printf " MB\n"
    if float_gt "$MEM_USED_MB" "$RAM_LIMIT_VALUE"; then
      echo "⚠️  RAM sopra la soglia (assoluta)!"
      RESTART=1
    fi
  else
    echo "Limite RAM (percentuale): ${RAM_LIMIT_VALUE}%"
    if [[ -z "$MEM_PCT_USED" ]]; then
      echo "⚠️  Impossibile calcolare la percentuale RAM (limite non disponibile). Salto controllo RAM%."
    else
      if float_gt "$MEM_PCT_USED" "$RAM_LIMIT_VALUE"; then
        echo "⚠️  RAM sopra la soglia (percentuale)!"
        RESTART=1
      fi
    fi
  fi
else
  echo "RAM check disabilitato."
fi

# --- Restart se necessario ---
if [[ "$RESTART" -eq 1 ]]; then
  echo "🔄 Riavvio container '$CONTAINER_NAME'..."
  if ! $RUNTIME restart "$CONTAINER_NAME"; then
    echo "Errore durante il riavvio del container."
    exit 1
  fi
  echo "✅ Riavviato."
else
  echo "✅ Container nei limiti."
fi
echo "################ END ################"
exit 0