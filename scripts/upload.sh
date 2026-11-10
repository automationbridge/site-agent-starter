#!/bin/bash
# Uploads one image or file to the website's Media Library and prints its public address on the last line.
#
# Usage: bash scripts/upload.sh images/photo.jpg

file="${1:?Usage: bash scripts/upload.sh path/to/file}"

[ -f "$file" ] || { echo "No file at $file"; exit 1; }

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

name="$(basename "$file")"

case "$(printf '%s' "${name##*.}" | tr '[:upper:]' '[:lower:]')" in
	jpg|jpeg) type='image/jpeg' ;;
	png) type='image/png' ;;
	gif) type='image/gif' ;;
	webp) type='image/webp' ;;
	svg) type='image/svg+xml' ;;
	pdf) type='application/pdf' ;;
	mp4) type='video/mp4' ;;
	*) echo "Unsupported file type: $name"; exit 1 ;;
esac

answer="$(mktemp)"
trap 'rm -f "$answer"' EXIT

code="$(printf 'user = "%s:%s"\n' "$WP_ADMIN_USER" "$WP_ADMIN_APP_PASSWORD" | curl -sS -m 300 -K - -o "$answer" -w '%{http_code}' \
	-X POST -H "Content-Type: $type" -H "Content-Disposition: attachment; filename=\"$name\"" \
	--data-binary "@$file" "$site/wp-json/wp/v2/media")"

if [ "$code" != "201" ]; then
	echo "Upload failed with HTTP $code:"
	cat "$answer"
	exit 1
fi

python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["source_url"])' "$answer"
