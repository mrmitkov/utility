#!/bin/bash

SOURCE_DIR="/photos/temp"
DEST_DIR="/photos/clone_dates"
HOSTNAME=$(hostname)
START_DATE="2024-10-01"
TODAY=$(date +%Y-%m-%d)

echo "Scanning files..."
mapfile -t files < <(find "$SOURCE_DIR" -type f -newermt "$START_DATE" ! -newermt "$TODAY")

total=${#files[@]}
count=0
declare -a failed_files

echo "Found $total file(s) to process."


for filepath in "${files[@]}"; do
    ((count++))
    percent=$((count * 100 / total))
    echo -ne "Copying [$count/$total] $percent%...\r"

    file_date=$(date -r "$filepath" +%Y-%m)
    target_dir="$DEST_DIR/$HOSTNAME/$file_date"
    [ -d "$target_dir" ] || mkdir -p "$target_dir"

    if ! rsync -a "$filepath" "$target_dir/"; then
        failed_files+=("$filepath")
    fi
done
if (( ${#failed_files[@]} > 0 )); then
    echo -e "\n⚠️  The following files failed to copy:"
    for f in "${failed_files[@]}"; do
        echo " - $f"
    done
else
    echo "✅ All files copied successfully."
fi
