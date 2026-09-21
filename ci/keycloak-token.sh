#!/usr/bin/env bash
# Chiede a Keycloak un token per l'account di servizio della CI e lo stampa.
#
# Variabili attese (dai secrets del repository):
#   KEYCLOAK_TOKEN_URL   es. https://auth.christiandellisanti.uk/realms/measurestream/protocol/openid-connect/token
#   TEMPLATE_CLIENT_ID   il client con il ruolo TEMPLATE_PUBLISHER
#   TEMPLATE_CLIENT_SECRET
set -euo pipefail

: "${KEYCLOAK_TOKEN_URL:?manca KEYCLOAK_TOKEN_URL}"
: "${TEMPLATE_CLIENT_ID:?manca TEMPLATE_CLIENT_ID}"
: "${TEMPLATE_CLIENT_SECRET:?manca TEMPLATE_CLIENT_SECRET}"

response=$(curl -sS --fail-with-body -X POST "$KEYCLOAK_TOKEN_URL" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  --data-urlencode "client_id=$TEMPLATE_CLIENT_ID" \
  --data-urlencode "client_secret=$TEMPLATE_CLIENT_SECRET")

token=$(printf '%s' "$response" | jq -r '.access_token // empty')
if [ -z "$token" ]; then
  echo "Keycloak non ha restituito un access_token" >&2
  exit 1
fi
printf '%s' "$token"
