#!/bin/bash
set -euo pipefail

ORG="ORG1"
PRODUCT="Ubuntu"
ARCH="amd64"

ARCHIVE_URL="http://archive.ubuntu.com/ubuntu"
SECURITY_URL="http://security.ubuntu.com/ubuntu"
COMPONENTS=("main" "universe" "restricted" "multiverse")

while true; do
  read -r -p "Vuoi aggiungere tutti i repository [T], scegliere manualmente [S] o abortire [A]? " selection
  case "${selection^^}" in
    T) SELECTION_MODE="T"; break ;;
    S) SELECTION_MODE="S"; break ;;
    A) echo "Operazione annullata."; exit 0 ;;
    *) echo "Risposta non valida. Inserisci T, S oppure A." ;;
  esac
done

hammer product create \
  --name "$PRODUCT" \
  --organization "$ORG" || true

CREATED_REPOSITORIES=()

confirm_repository () {
  local repo_name="$1"
  local answer

  while true; do
    read -r -p "Creare il repository '$repo_name'? [y/n] " answer
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "Risposta non valida. Inserisci y/yes oppure n/no." ;;
    esac
  done
}

create_repo () {
  local name="$1"
  local release="$2"
  local component="$3"
  local url="$4"

  if [[ "$SELECTION_MODE" == "S" ]] && ! confirm_repository "$name"; then
    echo "Skipping repository: $name"
    return 0
  fi

  hammer repository create \
    --name "$name" \
    --organization "$ORG" \
    --product "$PRODUCT" \
    --content-type "deb" \
    --download-policy "on_demand" \
    --mirror-on-sync true \
    --url "$url" \
    --deb-releases "$release" \
    --deb-components "$component" \
    --deb-architectures "$ARCH"
  CREATED_REPOSITORIES+=("$name")
}
## Ubuntu 24.04 (noble)
# Base
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu24-noble-$comp" "noble" "$comp" "$ARCHIVE_URL"
done
# Updates
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu24-noble-updates-$comp" "noble-updates" "$comp" "$ARCHIVE_URL"
done
# Security
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu24-noble-security-$comp" "noble-security" "$comp" "$SECURITY_URL"
done
# Backports (optional)
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu24-noble-backports-$comp" "noble-backports" "$comp" "$ARCHIVE_URL"
done

## Ubuntu 22.04 (jammy)
# Base
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu22-jammy-$comp" "jammy" "$comp" "$ARCHIVE_URL"
done
# Updates
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu22-jammy-updates-$comp" "jammy-updates" "$comp" "$ARCHIVE_URL"
done
# Security
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu22-jammy-security-$comp" "jammy-security" "$comp" "$SECURITY_URL"
done
# Backports (optional)
for comp in "${COMPONENTS[@]}"; do
  create_repo "ubuntu22-jammy-backports-$comp" "jammy-backports" "$comp" "$ARCHIVE_URL"
done

for repo_name in "${CREATED_REPOSITORIES[@]}"; do
  echo "Synchronizing repository: $repo_name"
  hammer repository synchronize \
    --name "$repo_name" \
    --product "$PRODUCT" \
    --organization "$ORG" \
    --async
done
