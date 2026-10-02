#!/usr/bin/env bash
set -euo pipefail

ORG="ORG1"
PRODUCT="ATIX Subscription Manager"
BASE_URL="https://oss.atix.de"
APT_ARCH="amd64"

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

create_deb_repo() {
	local distro="$1"
	local repo_name="$2"

	if [[ "$SELECTION_MODE" == "S" ]] && ! confirm_repository "$repo_name"; then
		echo "Skipping repository: $repo_name"
		return 0
	fi

	echo "Creating APT repository: $repo_name"
	hammer repository create \
		--name "$repo_name" \
		--organization "$ORG" \
		--product "$PRODUCT" \
		--content-type "deb" \
		--download-policy "on_demand" \
		--mirror-on-sync true \
		--url "$BASE_URL/$distro/" \
		--deb-releases "stable" \
		--deb-components "main" \
		--deb-architectures "$APT_ARCH"
	CREATED_REPOSITORIES+=("$repo_name")
}

create_yum_repo() {
	local distro="$1"
	local repo_name="$2"

	if [[ "$SELECTION_MODE" == "S" ]] && ! confirm_repository "$repo_name"; then
		echo "Skipping repository: $repo_name"
		return 0
	fi

	echo "Creating RPM repository: $repo_name"
	hammer repository create \
		--name "$repo_name" \
		--organization "$ORG" \
		--product "$PRODUCT" \
		--content-type "yum" \
		--download-policy "on_demand" \
		--mirror-on-sync true \
		--url "$BASE_URL/$distro/"
	CREATED_REPOSITORIES+=("$repo_name")
}

# Debian (Debian 11 is unmaintained upstream)
create_deb_repo "Debian11" "Debian 11 (Bullseye)"
create_deb_repo "Debian12" "Debian 12 (Bookworm)"
create_deb_repo "Debian13" "Debian 13 (Trixie)"

# Ubuntu (20.04 and 22.04 are unmaintained upstream)
create_deb_repo "Ubuntu20LTS" "Ubuntu 20.04 (Focal)"
create_deb_repo "Ubuntu22LTS" "Ubuntu 22.04 (Jammy)"
create_deb_repo "Ubuntu24LTS" "Ubuntu 24.04 (Noble)"
create_deb_repo "Ubuntu26LTS" "Ubuntu 26.04 (Resolute)"

# SLES (older service packs are unmaintained upstream)
create_yum_repo "SLES12SP5" "SLES 12 SP5"
create_yum_repo "SLES15SP5" "SLES 15 SP5"
create_yum_repo "SLES15SP6" "SLES 15 SP6"
create_yum_repo "SLES15SP7" "SLES 15 SP7"
create_yum_repo "SLES16_0" "SLES 16.0"

for repo_name in "${CREATED_REPOSITORIES[@]}"; do
	echo "Synchronizing repository: $repo_name"
	hammer repository synchronize \
		--name "$repo_name" \
		--product "$PRODUCT" \
		--organization "$ORG" \
		--async
done
