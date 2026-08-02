#!/usr/bin/env bash
set -euo pipefail

source /workspace/.ci-workflows/hooks/lib/distro.sh
source /workspace/.ci-workflows/hooks/lib/common.sh || true

RPM_REPO_FILE="/etc/yum.repos.d/prefork-packages.repo"
RPM_KEY_FILE="/etc/pki/rpm-gpg/prefork-packages.asc"
DEB_LIST_FILE="/etc/apt/sources.list.d/prefork-packages.list"
DEB_SOURCES_FILE="/etc/apt/sources.list.d/prefork-packages.sources"
DEB_KEY_FILE="/usr/share/keyrings/prefork-packages.asc"

assert_file_exists() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: expected file missing: $path" >&2
    exit 1
  fi
}

assert_file_contains() {
  local path="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$path"; then
    echo "ERROR: expected content not found in $path" >&2
    echo "       missing: $needle" >&2
    exit 1
  fi
}

resolve_codename() {
  local codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"

  if [[ -z "$codename" ]] && command -v lsb_release >/dev/null 2>&1; then
    codename="$(lsb_release -sc 2>/dev/null || true)"
  fi

  if [[ -z "$codename" ]]; then
    echo "ERROR: unable to determine distro codename" >&2
    exit 1
  fi

  printf '%s' "$codename"
}

supports_deb822() {
  local codename="$1"

  case "$codename" in
    buster|focal|jammy)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

log "Smoke test for prefork-packages on distro: $ID ($ID_LIKE), format: $PACKAGE_FORMAT"

if is_fedora; then
  assert_file_exists "$RPM_REPO_FILE"
  assert_file_exists "$RPM_KEY_FILE"

  assert_file_contains "$RPM_REPO_FILE" "[prefork-packages]"
  assert_file_contains "$RPM_REPO_FILE" "name=Fedora prefork-packages"
  assert_file_contains "$RPM_REPO_FILE" 'baseurl=https://packages.private.prefork.de/fedora/$releasever/'
  assert_file_contains "$RPM_REPO_FILE" "gpgkey=file:///etc/pki/rpm-gpg/prefork-packages.asc"
  assert_file_contains "$RPM_KEY_FILE" "BEGIN PGP PUBLIC KEY BLOCK"

  log "Smoke test passed for Fedora"
  exit 0
fi

if is_el; then
  assert_file_exists "$RPM_REPO_FILE"
  assert_file_exists "$RPM_KEY_FILE"

  assert_file_contains "$RPM_REPO_FILE" "[prefork-packages]"
  assert_file_contains "$RPM_REPO_FILE" "name=EPEL prefork-packages"
  assert_file_contains "$RPM_REPO_FILE" 'baseurl=https://packages.private.prefork.de/epel/$releasever/'
  assert_file_contains "$RPM_REPO_FILE" "gpgkey=file:///etc/pki/rpm-gpg/prefork-packages.asc"
  assert_file_contains "$RPM_KEY_FILE" "BEGIN PGP PUBLIC KEY BLOCK"

  log "Smoke test passed for EL"
  exit 0
fi

if is_deb_based; then
  codename="$(resolve_codename)"
  base_path="debian"
  if is_ubuntu; then
    base_path="ubuntu"
  fi

  assert_file_exists "$DEB_KEY_FILE"
  assert_file_contains "$DEB_KEY_FILE" "BEGIN PGP PUBLIC KEY BLOCK"

  if supports_deb822 "$codename"; then
    assert_file_exists "$DEB_SOURCES_FILE"
    assert_file_contains "$DEB_SOURCES_FILE" "Types: deb"
    assert_file_contains "$DEB_SOURCES_FILE" "URIs: https://packages.private.prefork.de/${base_path}/"
    assert_file_contains "$DEB_SOURCES_FILE" "Suites: ${codename}"
    assert_file_contains "$DEB_SOURCES_FILE" "Components: main"
    assert_file_contains "$DEB_SOURCES_FILE" "Signed-By: /usr/share/keyrings/prefork-packages.asc"
  else
    assert_file_exists "$DEB_LIST_FILE"
    assert_file_contains "$DEB_LIST_FILE" "deb [signed-by=/usr/share/keyrings/prefork-packages.asc] https://packages.private.prefork.de/${base_path}/ ${codename} main"
  fi

  log "Smoke test passed for Debian/Ubuntu"
  exit 0
fi

echo "ERROR: unsupported distro for prefork-packages smoke test: $ID" >&2
exit 1
