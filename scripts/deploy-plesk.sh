#!/usr/bin/env bash
# npm run deploy:plesk

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

PLESK_HOST="${PLESK_HOST:-89.19.30.85}"
PLESK_USER="${PLESK_USER:-u2780092}"
PLESK_PASS="${PLESK_PASS:-}"

if [[ -z "$PLESK_PASS" ]]; then
  read -r -s -p "Plesk password: " PLESK_PASS
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
  "--exclude-glob .env"
  "--exclude-glob .env.local"
  "--exclude-glob .env.local.example"
  "--exclude-glob scripts/"
)

EXCLUDE_ARGS="$(printf '%s ' "${EXCLUDES[@]}")"

echo "Deploying to Plesk host: $PLESK_HOST"
echo "Target directory: /httpdocs/"

lftp -u "${PLESK_USER},${PLESK_PASS}" "ftp://${PLESK_HOST}" -e "
set ssl:verify-certificate no;
lcd ${REPO_ROOT};
mirror -R --verbose ${EXCLUDE_ARGS} ./ /httpdocs/;
bye
"

echo "Deploy completed successfully."
