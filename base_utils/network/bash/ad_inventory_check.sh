#!/usr/bin/env bash

set -o pipefail

#######################################
# CONFIGURAZIONE
#######################################

PING_TIMEOUT=3
SSH_TIMEOUT=3
RDP_TIMEOUT=3
RDP_PORT=3389
LDAP_TIMEOUT=10
MAX_PARALLEL=${MAX_PARALLEL:-10}

#######################################
# COLORI
#######################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

#######################################
# DIPENDENZE
#######################################

check_dependencies() {

    local missing=()

    local packages=(
        dnsutils
        iputils-ping
        netcat-openbsd
        ldap-utils
        jq
    )

    echo "Verifica prerequisiti..."

    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done

    if [ ${#missing[@]} -ne 0 ]; then

        echo
        echo "Pacchetti mancanti:"
        printf ' - %s\n' "${missing[@]}"
        echo

        read -rp "Installarli? [y/N] : " ans

        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo apt update
            sudo apt install -y "${missing[@]}"
        else
            echo "Impossibile continuare."
            exit 1
        fi
    fi
}

#######################################
# KERBEROS
#######################################

check_kerberos() {

    echo "Verifica ticket Kerberos..."

    if ! klist -s; then
        echo
        echo "Ticket Kerberos assente o scaduto."
        echo "Eseguire kinit prima del test."
        exit 1
    fi

    echo "Kerberos OK"
}

#######################################
# DOMAIN CONTROLLER
#######################################

select_domain_controller() {

    local domain
    local srv_records
    local choice
    local -a DCS=()

    domain=$(dnsdomainname)

    if [ -z "$domain" ]; then
        echo "Impossibile determinare il dominio."
        return 1
    fi

    echo
    echo "Ricerca Domain Controller..."

    if ! srv_records=$(dig +short SRV "_ldap._tcp.$domain"); then
        echo "Impossibile recuperare i record SRV LDAP per $domain."
        return 1
    fi

    mapfile -t DCS < <(
        awk 'NF >= 4 && $4 != "." { target = $4; sub(/\.$/, "", target); print target }' \
            <<< "$srv_records" \
            | sort -u
    )

    if [ ${#DCS[@]} -eq 0 ]; then
        echo "Nessun Domain Controller trovato per $domain."
        return 1
    fi

    echo
    echo "Domain Controller disponibili:"
    echo

    for i in "${!DCS[@]}"; do
        printf "%2d) %s\n" "$((i + 1))" "${DCS[$i]}"
    done

    echo

    while true; do
        if ! read -rp "Seleziona il DC: " choice; then
            echo
            echo "Selezione del Domain Controller annullata."
            return 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
            (( 10#$choice >= 1 && 10#$choice <= ${#DCS[@]} )); then
            DC="${DCS[$((10#$choice - 1))]}"
            break
        fi

        echo "Scelta non valida."
    done

    echo
    echo "DC selezionato: $DC"
}

#######################################
# LDAP BASE DN
#######################################

discover_base_dn() {

    local root_dse

    if ! root_dse=$(ldapsearch \
        -LLL \
        -H "ldap://$DC" \
        -Y GSSAPI \
        -Q \
        -o nettimeout="$LDAP_TIMEOUT" \
        -s base \
        -b "" \
        defaultNamingContext); then
        echo "Impossibile recuperare il defaultNamingContext da $DC."
        return 1
    fi

    BASE_DN=$(awk -F': ' '$1 == "defaultNamingContext" { print substr($0, index($0, ": ") + 2); exit }' <<< "$root_dse")

    if [ -z "$BASE_DN" ]; then
        echo "Il Domain Controller $DC non ha restituito defaultNamingContext."
        return 1
    fi
}

#######################################
# PARSING INVENTORY
#######################################

read_hosts() {

    local file="$1"

    grep -v '^\[' "$file" \
        | grep -v '^#' \
        | grep -v '^;' \
        | sed '/^$/d' \
        | awk -F= '{print $NF}' \
        | sed 's/^[ \t]*//;s/[ \t]*$//'
}

#######################################
# DNS
#######################################

check_dns() {

    local host="$1"

    local ip

    ip=$(getent ahostsv4 "$host" 2>/dev/null | awk '{print $1}' | head -1)

    if [ -n "$ip" ]; then
        echo "$ip"
    else
        echo ""
    fi
}

#######################################
# ICMP
#######################################

check_ping() {

    local host="$1"

    ping -W "$PING_TIMEOUT" -c 1 "$host" >/dev/null 2>&1
}

#######################################
# SSH
#######################################

check_ssh() {

    local host="$1"

    nc -z -w "$SSH_TIMEOUT" "$host" 22 >/dev/null 2>&1
}

#######################################
# RDP
#######################################

check_rdp() {

    local host="$1"

    nc -z -w "$RDP_TIMEOUT" "$host" "$RDP_PORT" >/dev/null 2>&1
}

#######################################
# LDAP COMPUTER OBJECT
#######################################

check_ad_computer() {

    local host="$1"

    local short

    short=$(echo "$host" | cut -d'.' -f1)

    ldapsearch \
        -LLL \
        -H "ldap://$DC" \
        -Y GSSAPI \
        -Q \
        -o nettimeout="$LDAP_TIMEOUT" \
        -o ldif-wrap=0 \
        -b "$BASE_DN" \
        "(&(objectClass=computer)(cn=$short))" \
        distinguishedName
}

analyze_host() {

    local host="$1"
    local ip icmp ssh rdp ad dn ldap_result

    ip=$(check_dns "$host")

    if check_ping "$host"; then
        icmp="OK"
    else
        icmp="KO"
    fi

    if check_ssh "$host"; then
        ssh="OK"
    else
        ssh="KO"
    fi

    if check_rdp "$host"; then
        rdp="OK"
    else
        rdp="KO"
    fi

    if ldap_result=$(check_ad_computer "$host"); then
        dn=$(awk -F': ' '$1 == "distinguishedName" { print substr($0, index($0, ": ") + 2); exit }' <<< "$ldap_result")

        if [ -n "$dn" ]; then
            ad="PRESENTE"
        else
            ad="ASSENTE"
        fi
    else
        echo "Errore nella query LDAP per $host." >&2
        ad="ERRORE"
        dn=""
    fi

    printf '%s|%s|%s|%s|%s|%s|%s\n' \
        "$host" "${ip:-NO_DNS}" "$icmp" "$ssh" "$rdp" "$ad" "$dn"
}

#######################################
# OUTPUT
#######################################

declare -a REPORT_ROWS

add_row() {

    REPORT_ROWS+=("$1|$2|$3|$4|$5|$6|$7")
}

show_table() {

    printf "\n"

    printf "%-35s %-16s %-8s %-8s %-8s %-12s %-40s\n" \
        "HOST" "IP" "ICMP" "SSH" "RDP" "AD" "DN"

    printf '%.0s-' {1..140}
    printf "\n"

    for row in "${REPORT_ROWS[@]}"; do
        IFS='|' read -r HOST IP ICMP SSH RDP AD DN <<< "$row"

        printf "%-35s %-16s %-8s %-8s %-8s %-12s %-40s\n" \
            "$HOST" "$IP" "$ICMP" "$SSH" "$RDP" "$AD" "$DN"
    done

    printf "\n"
}

#######################################
# CSV
#######################################

export_csv() {

    local file="$1"

    printf "Host,IP,ICMP,SSH,RDP,AD,DN\n" > "$file"

    for row in "${REPORT_ROWS[@]}"; do
        echo "$row" | tr '|' ',' >> "$file"
    done
}

#######################################
# JSON
#######################################

export_json() {

    local file="$1"

    {
        echo "["

        local first=true

        for row in "${REPORT_ROWS[@]}"; do

            IFS='|' read -r HOST IP ICMP SSH RDP AD DN <<< "$row"

            if [ "$first" = false ]; then
                echo ","
            fi

            jq -n \
                --arg host "$HOST" \
                --arg ip "$IP" \
                --arg icmp "$ICMP" \
                --arg ssh "$SSH" \
                --arg rdp "$RDP" \
                --arg ad "$AD" \
                --arg dn "$DN" \
                '{
                    host:$host,
                    ip:$ip,
                    icmp:$icmp,
                    ssh:$ssh,
                    rdp:$rdp,
                    ad:$ad,
                    distinguishedName:$dn
                 }'

            first=false

        done

        echo "]"

    } > "$file"
}

#######################################
# HTML
#######################################

export_html() {

    local file="$1"

    cat > "$file" <<EOF
<html>
<head>
<title>Inventory Report</title>
<style>
table {
 border-collapse: collapse;
 width:100%;
}
th,td{
 border:1px solid black;
 padding:8px;
}
th{
 background:#dcdcdc;
}
</style>
</head>
<body>

<h2>Inventory Validation Report</h2>

<table>
<tr>
<th>Host</th>
<th>IP</th>
<th>ICMP</th>
<th>SSH</th>
<th>RDP</th>
<th>AD</th>
<th>DN</th>
</tr>
EOF

    for row in "${REPORT_ROWS[@]}"; do

        IFS='|' read -r HOST IP ICMP SSH RDP AD DN <<< "$row"

        cat >> "$file" <<EOF
<tr>
<td>$HOST</td>
<td>$IP</td>
<td>$ICMP</td>
<td>$SSH</td>
<td>$RDP</td>
<td>$AD</td>
<td>$DN</td>
</tr>
EOF

    done

    cat >> "$file" <<EOF
</table>
</body>
</html>
EOF
}

#######################################
# XML
#######################################

export_xml() {

    local file="$1"

    {
        echo "<hosts>"

        for row in "${REPORT_ROWS[@]}"; do

            IFS='|' read -r HOST IP ICMP SSH RDP AD DN <<< "$row"

            cat <<EOF
<host>
 <name>$HOST</name>
 <ip>$IP</ip>
 <icmp>$ICMP</icmp>
 <ssh>$SSH</ssh>
 <rdp>$RDP</rdp>
 <ad>$AD</ad>
 <distinguishedName>$DN</distinguishedName>
</host>
EOF

        done

        echo "</hosts>"
    } > "$file"
}

#######################################
# MAIN
#######################################

if [ $# -ne 1 ]; then
    echo "Uso:"
    echo "$0 inventory.ini"
    exit 1
fi

INVENTORY="$1"

[ ! -f "$INVENTORY" ] && {
    echo "File non trovato: $INVENTORY"
    exit 1
}

if [[ ! "$MAX_PARALLEL" =~ ^[1-9][0-9]*$ ]]; then
    echo "MAX_PARALLEL deve essere un intero positivo." >&2
    exit 1
fi

check_dependencies
check_kerberos
select_domain_controller || exit 1
discover_base_dn || exit 1

echo
echo "Domain Controller: $DC"
echo "Base DN: $BASE_DN"
echo

mapfile -t HOSTS < <(read_hosts "$INVENTORY")
RESULTS_DIR=$(mktemp -d) || {
    echo "Impossibile creare la directory temporanea dei risultati." >&2
    exit 1
}
trap 'rm -rf -- "$RESULTS_DIR"' EXIT

declare -a ACTIVE_INDICES=()
declare -a ACTIVE_PIDS=()
declare -a REMAINING_INDICES=()
SPINNER_CHARS=('|' '/' '-' '\')
SPINNER_INDEX=0
NEXT_HOST=0
COMPLETED_HOSTS=0
TOTAL_HOSTS=${#HOSTS[@]}
ANALYSIS_FAILED=0
PROGRESS_UI=0
TERMINAL_ROWS=0
TERMINAL_COLS=0
SCROLL_END=0
UI_HOST_ROWS=0

clear_progress_ui() {

    local row

    (( PROGRESS_UI )) || return 0

    printf '\033[r'
    for ((row = SCROLL_END + 1; row <= TERMINAL_ROWS; row++)); do
        printf '\033[%d;1H\033[2K' "$row"
    done
    printf '\033[%d;1H' "$((SCROLL_END + 1))"
    PROGRESS_UI=0
}

configure_progress_ui() {

    local dimensions rows columns

    [ -t 1 ] || return 1
    dimensions=$(stty size < /dev/tty 2>/dev/null) || return 1
    read -r rows columns <<< "$dimensions"
    if [[ ! "$rows" =~ ^[0-9]+$ || ! "$columns" =~ ^[0-9]+$ ]] ||
        (( rows < 4 || columns < 10 )); then
        clear_progress_ui
        return 1
    fi

    if (( PROGRESS_UI )) &&
        (( rows == TERMINAL_ROWS && columns == TERMINAL_COLS )); then
        return 0
    fi

    clear_progress_ui
    TERMINAL_ROWS="$rows"
    TERMINAL_COLS="$columns"
    UI_HOST_ROWS=$(( rows - 3 ))
    if (( UI_HOST_ROWS > MAX_PARALLEL )); then
        UI_HOST_ROWS="$MAX_PARALLEL"
    fi
    SCROLL_END=$(( rows - UI_HOST_ROWS - 1 ))

    printf '\033[1;%dr\033[%d;1H' "$SCROLL_END" "$SCROLL_END"
    PROGRESS_UI=1
}

render_progress() {

    local index slot row status progress_bar="" percent=0
    local bar_width filled suffix remaining

    configure_progress_ui || return 0

    for ((slot = 0; slot < UI_HOST_ROWS; slot++)); do
        row=$(( SCROLL_END + 1 + slot ))
        status=""
        if (( ${#ACTIVE_INDICES[@]} > UI_HOST_ROWS && slot == UI_HOST_ROWS - 1 )); then
            remaining=$(( ${#ACTIVE_INDICES[@]} - UI_HOST_ROWS + 1 ))
            status="+$remaining altri host in analisi"
        elif (( slot < ${#ACTIVE_INDICES[@]} )); then
            index="${ACTIVE_INDICES[$slot]}"
            status="In Analysis ${HOSTS[$index]} - [${SPINNER_CHARS[$SPINNER_INDEX]}]"
        fi
        printf '\033[%d;1H\033[2K%.*s' "$row" "$TERMINAL_COLS" "$status"
    done

    if (( TOTAL_HOSTS > 0 )); then
        percent=$(( COMPLETED_HOSTS * 100 / TOTAL_HOSTS ))
    fi
    suffix=" $COMPLETED_HOSTS/$TOTAL_HOSTS ($percent%)"
    bar_width=$(( TERMINAL_COLS - ${#suffix} - 2 ))
    (( bar_width < 0 )) && bar_width=0
    filled=$(( COMPLETED_HOSTS * bar_width / (TOTAL_HOSTS > 0 ? TOTAL_HOSTS : 1) ))

    for ((index = 0; index < bar_width; index++)); do
        if (( index < filled )); then
            progress_bar+="|"
        else
            progress_bar+=" "
        fi
    done

    row="$TERMINAL_ROWS"
    printf '\033[%d;1H\033[2K%.*s' "$row" "$TERMINAL_COLS" "[$progress_bar]$suffix"
    printf '\033[%d;1H' "$SCROLL_END"
}

print_host_status() {

    if (( PROGRESS_UI )); then
        printf '\033[%d;1H\033[2K%s\n' "$SCROLL_END" "$1"
    else
        printf '%s\n' "$1"
    fi
}

trap 'clear_progress_ui; rm -rf -- "$RESULTS_DIR"' EXIT
trap 'render_progress' WINCH

while (( NEXT_HOST < ${#HOSTS[@]} || ${#ACTIVE_INDICES[@]} > 0 )); do
    while (( NEXT_HOST < ${#HOSTS[@]} && ${#ACTIVE_INDICES[@]} < MAX_PARALLEL )); do
        HOST="${HOSTS[$NEXT_HOST]}"

        #print_host_status "Analisi $HOST - in corso"

        ( analyze_host "$HOST" ) \
            > "$RESULTS_DIR/$NEXT_HOST.row" \
            2> "$RESULTS_DIR/$NEXT_HOST.err" &
        ACTIVE_PIDS[$NEXT_HOST]=$!
        ACTIVE_INDICES+=("$NEXT_HOST")
        ((NEXT_HOST += 1))
        render_progress
    done

    REMAINING_INDICES=()
    for index in "${ACTIVE_INDICES[@]}"; do
        pid="${ACTIVE_PIDS[$index]}"

        if kill -0 "$pid" 2>/dev/null; then
            REMAINING_INDICES+=("$index")
            continue
        fi

        if ! wait "$pid"; then
            if (( PROGRESS_UI )); then
                printf '\033[%d;1H\033[2K' "$SCROLL_END"
            fi
            echo "Errore durante l'analisi di ${HOSTS[$index]}." >&2
            ANALYSIS_FAILED=1
        fi
        ((COMPLETED_HOSTS += 1))

        if [ -s "$RESULTS_DIR/$index.row" ]; then
            :
        else
            echo "Nessun risultato ricevuto per ${HOSTS[$index]}." >&2
            ANALYSIS_FAILED=1
        fi

        if [ -s "$RESULTS_DIR/$index.err" ]; then
            if [ -t 1 ]; then
                cat "$RESULTS_DIR/$index.err"
            else
                cat "$RESULTS_DIR/$index.err" >&2
            fi
        fi
        print_host_status "Analyzed ${HOSTS[$index]} - DONE"
    done
    ACTIVE_INDICES=("${REMAINING_INDICES[@]}")
    render_progress

    if (( ${#ACTIVE_INDICES[@]} > 0 )); then
        SPINNER_INDEX=$(( (SPINNER_INDEX + 1) % ${#SPINNER_CHARS[@]} ))
        sleep 0.2
    fi
done

clear_progress_ui

for i in "${!HOSTS[@]}"; do
    if [ -s "$RESULTS_DIR/$i.row" ]; then
        IFS='|' read -r host ip icmp ssh rdp ad dn < "$RESULTS_DIR/$i.row"
        add_row "$host" "$ip" "$icmp" "$ssh" "$rdp" "$ad" "$dn"
    fi
done

if (( ANALYSIS_FAILED )); then
    exit 1
fi

show_table

echo
read -rp "Vuoi esportare un report? [y/N] : " EXPORT

if [[ ! "$EXPORT" =~ ^[Yy]$ ]]; then
    exit 0
fi

read -rp "Directory destinazione: " DEST

mkdir -p "$DEST"

read -rp "Nome base report (senza estensione): " BASENAME

echo
echo "Formati disponibili:"
echo "1) CSV"
echo "2) JSON"
echo "3) HTML"
echo "4) XML"
echo "5) TUTTI"

read -rp "Scelta: " CHOICE

case "$CHOICE" in

1)
    export_csv "$DEST/$BASENAME.csv"
    ;;

2)
    export_json "$DEST/$BASENAME.json"
    ;;

3)
    export_html "$DEST/$BASENAME.html"
    ;;

4)
    export_xml "$DEST/$BASENAME.xml"
    ;;

5)
    export_csv  "$DEST/$BASENAME.csv"
    export_json "$DEST/$BASENAME.json"
    export_html "$DEST/$BASENAME.html"
    export_xml  "$DEST/$BASENAME.xml"
    ;;

*)
    echo "Scelta non valida"
    ;;
esac

echo
echo "Report generato in: $DEST"