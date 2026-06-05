#!/bin/bash

LIST="shares.txt"

read -p "Domain: " DOMAIN
read -p "Username: " USER
read -s -p "Password: " PASS
echo ""

AUTH_FILE=$(mktemp)
chmod 600 "$AUTH_FILE"

cat > "$AUTH_FILE" <<EOF
domain=$DOMAIN
username=$USER
password=$PASS
EOF

while read -r SHARE; do
    [[ -z "$SHARE" || "$SHARE" =~ ^# ]] && continue

    echo -n "Testing $SHARE ... "

    smbclient "$SHARE" -A "$AUTH_FILE" -m SMB3 -c "ls" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✅ OK"
    else
        echo "❌ FAIL"
    fi
done < "$LIST"

rm -f "$AUTH_FILE"