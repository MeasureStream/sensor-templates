#!/usr/bin/env bash
# Pubblica i template nel registro di sensor-manager.
#
#   ./ci/publish-templates.sh            pubblica    (POST /API/templates)
#   ./ci/publish-templates.sh --dry-run  solo referto (POST /API/templates/validate)
#
# Il `kind` non sta dentro i file: lo dice la cartella, esattamente come fa l'import del
# seme lato server. Un file che il registro rifiuta fa fallire il job con il suo messaggio.
set -euo pipefail

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

: "${TEMPLATE_API_URL:?manca TEMPLATE_API_URL}"   # es. https://www.christiandellisanti.uk
TOKEN=$(./ci/keycloak-token.sh)

if $DRY_RUN; then
  endpoint="$TEMPLATE_API_URL/API/templates/validate"
  azione="verificato"
else
  endpoint="$TEMPLATE_API_URL/API/templates"
  azione="pubblicato"
fi

pubblicati=0
for kind in sensor reference mu cu protocol; do
  case "$kind" in
    sensor)    cartella=sensors ;;
    reference) cartella=references ;;
    *)         cartella=$kind ;;
  esac
  [ -d "$cartella" ] || continue

  for file in "$cartella"/*.json; do
    [ -e "$file" ] || continue

    corpo=$(mktemp)
    codice=$(curl -sS -o "$corpo" -w '%{http_code}' -X POST "$endpoint?kind=$kind" \
      -H "Authorization: Bearer $TOKEN" \
      -H 'Content-Type: application/json' \
      --data-binary "@$file")

    if [ "$codice" != "200" ] && [ "$codice" != "201" ]; then
      echo "::error file=$file::il registro ha risposto $codice"
      cat "$corpo" >&2
      rm -f "$corpo"
      exit 1
    fi

    echo "$azione $file -> $(jq -r '"\(.kind) \(.templateId) \(.version // .resolvedVersion)"' "$corpo")"
    rm -f "$corpo"
    pubblicati=$((pubblicati + 1))
  done
done

echo "$pubblicati documenti: $azione"
