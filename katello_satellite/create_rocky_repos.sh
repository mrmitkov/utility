#!/usr/bin/env bash
set -euo pipefail

ORG="ORG1"
PRODUCT="Rocky"
ARCH="x86_64"
BASE_URL="https://download.rockylinux.org/pub/rocky"

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

confirm_repository() {
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

create_repo() {
  local name="$1"
  local version="$2"
  local repo_path="$3"

  local repo_url="${BASE_URL}/${version}/${repo_path}"

  if [[ "$SELECTION_MODE" == "S" ]] && ! confirm_repository "$name"; then
    echo "Skipping repository: $name"
    return 0
  fi

  echo "Creating repo: $name -> $repo_url"

  hammer repository create \
    --name "$name" \
    --organization "$ORG" \
    --product "$PRODUCT" \
    --content-type "yum" \
    --download-policy "on_demand" \
    --mirror-on-sync true \
    --url "$repo_url"
  CREATED_REPOSITORIES+=("$name")
}

# Rocky Linux 8.10
create_repo "8.10-baseos" "8.10" "BaseOS/${ARCH}/os"
create_repo "8.10-appstream" "8.10" "AppStream/${ARCH}/os"
create_repo "8.10-powertools" "8.10" "PowerTools/${ARCH}/os"
create_repo "8.10-extras" "8.10" "extras/${ARCH}/os"

# Rocky Linux 9.8
create_repo "9.8-baseos" "9.8" "BaseOS/${ARCH}/os"
create_repo "9.8-appstream" "9.8" "AppStream/${ARCH}/os"
create_repo "9.8-crb" "9.8" "CRB/${ARCH}/os"
create_repo "9.8-extras" "9.8" "extras/${ARCH}/os"

for repo_name in "${CREATED_REPOSITORIES[@]}"; do
  echo "Synchronizing repository: $repo_name"
  hammer repository synchronize \
    --name "$repo_name" \
    --product "$PRODUCT" \
    --organization "$ORG" \
    --async
done
