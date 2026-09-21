#!/usr/bin/env bash
# Chiede a Keycloak un token per l'account di servizio della CI e lo stampa.
#
# Variabili attese (dai secrets del repository):
#   KEYCLOAK_TOKEN_URL   es. https://auth.<dominio>/realms/measurestream/protocol/openid-connect/token
#   TEMPLATE_CLIENT_ID   il client con il ruolo TEMPLATE_PUBLISHER
#   TEMPLATE_CLIENT_SECRET
set -euo pipefail

: "${KEYCLOAK_TOKEN_URL:?manca KEYCLOAK_TOKEN_URL}"
: "${TEMPLATE_CLIENT_ID:?manca TEMPLATE_CLIENT_ID}"
: "${TEMPLATE_CLIENT_SECRET:?manca TEMPLATE_CLIENT_SECRET}"

# Un secret incollato a mano porta spesso con se' uno spazio o un a capo: Keycloak
# risponderebbe 401 senza che si capisca il motivo.
token_url=$(printf '%s' "$KEYCLOAK_TOKEN_URL" | tr -d ' \r\n')
client_id=$(printf '%s' "$TEMPLATE_CLIENT_ID" | tr -d ' \r\n')
client_secret=$(printf '%s' "$TEMPLATE_CLIENT_SECRET" | tr -d ' \r\n')

body=$(mktemp)
trap 'rm -f "$body"' EXIT

code=$(curl -sS -o "$body" -w '%{http_code}' -X POST "$token_url" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  --data-urlencode "client_id=$client_id" \
  --data-urlencode "client_secret=$client_secret")

if [ "$code" != "200" ]; then
  # La risposta di errore di Keycloak contiene error ed error_description, mai il segreto:
  # e' quello che dice se il problema e' il secret, il client o i service account.
  echo "::error::Keycloak ha risposto $code alla richiesta del token" >&2
  echo "URL: $token_url" >&2
  echo "client_id: $client_id" >&2
  cat "$body" >&2
  echo >&2
  exit 1
fi

token=$(jq -r '.access_token // empty' < "$body")
if [ -z "$token" ]; then
  echo "::error::Keycloak ha risposto 200 ma senza access_token" >&2
  cat "$body" >&2
  exit 1
fi
printf '%s' "$token"
