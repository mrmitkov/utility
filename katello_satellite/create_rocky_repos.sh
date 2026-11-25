#!/usr/bin/env bash
set -euo pipefail

ORG="ORG1"
PRODUCT="Rocky"
ARCH="x86_64"
BASE_URL="https://download.rockylinux.org/pub/rocky"
BASE_VAULT_URL="https://dl.rockylinux.org/vault/rocky"

if (($# > 0)); then
  ROCKY_VERSIONS=("$@")
else
  ROCKY_VERSIONS=("8.10" "9.8")
fi

for version in "${ROCKY_VERSIONS[@]}"; do
  if [[ ! "$version" =~ ^(8|9)\.([0-9]+)$ ]]; then
    echo "Versione Rocky non valida: '$version'. Usa il formato 8.x o 9.x." >&2
    exit 1
  fi
done

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
  local repo_url="$2"

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

create_version_repositories() {
  local version="$1"
  local major="${version%%.*}"
  local minor="${version#*.}"
  local minor_number=$((10#$minor))
  local base_url="$BASE_URL"
  local extra_repo

  if { [[ "$major" == "8" ]] && ((minor_number < 10)); } ||
     { [[ "$major" == "9" ]] && ((minor_number < 9)); }; then
    base_url="$BASE_VAULT_URL"
  fi

  if [[ "$major" == "8" ]]; then
    extra_repo="PowerTools"
  else
    extra_repo="CRB"
  fi

  create_repo "${version}-baseos" "${base_url}/${version}/BaseOS/${ARCH}/os"
  create_repo "${version}-appstream" "${base_url}/${version}/AppStream/${ARCH}/os"
  create_repo "${version}-${extra_repo,,}" "${base_url}/${version}/${extra_repo}/${ARCH}/os"
  create_repo "${version}-extras" "${base_url}/${version}/extras/${ARCH}/os"
}

for version in "${ROCKY_VERSIONS[@]}"; do
  create_version_repositories "$version"
done

for repo_name in "${CREATED_REPOSITORIES[@]}"; do
  echo "Synchronizing repository: $repo_name"
  hammer repository synchronize \
    --name "$repo_name" \
    --product "$PRODUCT" \
    --organization "$ORG" \
    --async
done
