#!/usr/bin/env bash

set -euo pipefail

if ! command -v lftp >/dev/null 2>&1; then
  echo "Error: lftp is not installed. Install it with: brew install lftp" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load untracked local env file if present.
if [[ -f "$REPO_ROOT/.env.local" ]]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env.local"
fi

IONOS_HOST="${IONOS_HOST:-access-5020135940.webspace-host.com}"
IONOS_USER="${IONOS_USER:-a2315925}"
IONOS_PASS="${IONOS_PASS:-}"

if [[ -z "$IONOS_PASS" ]]; then
  read -r -s -p "IONOS password: " IONOS_PASS
  echo
fi

EXCLUDES=(
  "--exclude-glob .git/"
  "--exclude-glob node_modules/"
  "--exclude-glob reports/"
  "--exclude-glob .gitignore"
  "--exclude-glob .gitattributes"
  "--exclude-glob package.json"
  "--exclude-glob package-lock.json"
)

EXCLUDE_ARGS="$(printf '%s ' "${EXCLUDES[@]}")"

echo "Deploying to IONOS host: $IONOS_HOST"
echo "Targets: / and /erolisildak.com/"

lftp -u "${IONOS_USER},${IONOS_PASS}" "sftp://${IONOS_HOST}" -e "
set sftp:auto-confirm yes;
lcd ${REPO_ROOT};
mirror -R --verbose ${EXCLUDE_ARGS} ./ /;
mirror -R --verbose ${EXCLUDE_ARGS} ./ /erolisildak.com/;
bye
"

echo "Deploy completed for both targets."