#!/bin/bash
ORG="ORG1"
PRODUCT="Ubuntu"
ARCH="amd64"

ARCHIVE_URL="http://archive.ubuntu.com/ubuntu"
SECURITY_URL="http://security.ubuntu.com/ubuntu"
COMPONENTS=("main" "universe" "restricted" "multiverse")


hammer product create \
  --name "$PRODUCT" \
  --organization "$ORG"

create_repo () {
  NAME=$1
  RELEASE=$2
  COMP=$3
  URL=$4

  hammer repository create \
    --name "$NAME" \
    --organization "$ORG" \
    --product "$PRODUCT" \
    --content-type "deb" \
    --url "$URL" \
    --deb-releases "$RELEASE" \
    --deb-components "$COMP" \
    --deb-architectures "$ARCH"

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

# Sync iniziale
hammer repository synchronize \
  --product "$PRODUCT" \
  --organization "$ORG" \
  --async
