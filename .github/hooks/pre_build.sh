#!/usr/bin/env bash
set -euo pipefail

# Libs aus dem ausgecheckten Workflow im Container
source /workspace/.ci-workflows/hooks/lib/distro.sh
source /workspace/.ci-workflows/hooks/lib/common.sh || true

log "Project pre-build hook – distro: $ID ($ID_LIKE)"

if is_rpm_based; then
	KEY_FILE="/workspace/prefork-packages.asc"
	SOURCES_DIR="/workspace/rpmbuild/SOURCES"

	if [[ ! -f "$KEY_FILE" ]]; then
		echo "ERROR: missing key source file: $KEY_FILE" >&2
		exit 1
	fi

	mkdir -p "$SOURCES_DIR"
	cp -f "$KEY_FILE" "$SOURCES_DIR/"
	log "Copied $(basename "$KEY_FILE") to $SOURCES_DIR"
fi
