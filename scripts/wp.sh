#!/bin/bash
# Calls the website's REST API as the connected admin, without ever printing the password.
#
# Usage: bash scripts/wp.sh METHOD /path [json-file]
#   bash scripts/wp.sh GET /site-agent/v1/settings
#   bash scripts/wp.sh POST /site-agent/v1/pages /tmp/page.json
#
# Reads WP_SITE, WP_ADMIN_USER and WP_ADMIN_APP_PASSWORD from the environment
# (Claude Code's environment settings). If any is missing, it reads a .env file
# in the repository's top folder instead, for running on your own computer.

method="${1:?Usage: bash scripts/wp.sh METHOD /path [json-file]}"
path="${2:?Usage: bash scripts/wp.sh METHOD /path [json-file]}"
body="${3:-}"

root="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "${WP_SITE:-}" ] || [ -z "${WP_ADMIN_USER:-}" ] || [ -z "${WP_ADMIN_APP_PASSWORD:-}" ]; then
	if [ -f "$root/.env" ]; then
		set -a
		. "$root/.env"
		set +a
	fi
fi

for name in WP_SITE WP_ADMIN_USER WP_ADMIN_APP_PASSWORD; do
	if [ -z "${!name:-}" ]; then
		echo "$name is not set. Add the three lines from Site Agent's Connect Claude button to Claude Code's environment settings."
		exit 1
	fi
done

site="${WP_SITE%/}"
case "$site" in http*) ;; *) site="https://$site" ;; esac

# The login goes to curl through a config on standard input, so it never appears in the process list or the output.
login="user = \"$WP_ADMIN_USER:$WP_ADMIN_APP_PASSWORD\""

if [ -n "$body" ]; then
	printf '%s\n' "$login" | curl -sS -m 300 -K - -w '\nHTTP %{http_code}\n' -X "$method" -H 'Content-Type: application/json' --data-binary "@$body" "$site/wp-json$path"
else
	printf '%s\n' "$login" | curl -sS -m 300 -K - -w '\nHTTP %{http_code}\n' -X "$method" "$site/wp-json$path"
fi
