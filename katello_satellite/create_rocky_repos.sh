#!/usr/bin/env bash
set -euo pipefail

ORG="ORG1"
PRODUCT="Rocky"
ARCH="x86_64"
BASE_URL="https://download.rockylinux.org/pub/rocky"

hammer product create \
  --name "$PRODUCT" \
  --organization "$ORG" || true

create_repo() {
  local NAME="$1"
  local VERSION="$2"
  local REPO_PATH="$3"

  local REPO_URL="${BASE_URL}/${VERSION}/${REPO_PATH}"

  echo "Creating repo: $NAME -> $REPO_URL"

  hammer repository create \
    --name "$NAME" \
    --organization "$ORG" \
    --product "$PRODUCT" \
    --content-type "yum" \
    --url "$REPO_URL"
}

# Rocky Linux 8.10
create_repo "rocky-8.10-baseos" "8.10" "BaseOS/${ARCH}/os"
create_repo "rocky-8.10-appstream" "8.10" "AppStream/${ARCH}/os"
create_repo "rocky-8.10-powertools" "8.10" "PowerTools/${ARCH}/os"
create_repo "rocky-8.10-extras" "8.10" "extras/${ARCH}/os"

# Rocky Linux 9.8
create_repo "rocky-9.8-baseos" "9.8" "BaseOS/${ARCH}/os"
create_repo "rocky-9.8-appstream" "9.8" "AppStream/${ARCH}/os"
create_repo "rocky-9.8-crb" "9.8" "CRB/${ARCH}/os"
create_repo "rocky-9.8-extras" "9.8" "extras/${ARCH}/os"

hammer repository synchronize \
  --product "$PRODUCT" \
  --organization "$ORG" \
  --async
