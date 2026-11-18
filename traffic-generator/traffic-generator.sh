#!/bin/sh

set -u

BASE_URL="${BASE_URL:-}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-5}"

if [ -z "$BASE_URL" ]; then
  echo "BASE_URL is required (for example, https://api.example.com)" >&2
  exit 1
fi

BASE_URL="${BASE_URL%/}"
request_number=0

request() {
  method="$1"
  path="$2"
  body="${3:-}"
  request_number=$((request_number + 1))
  request_id="mockoon-$(date +%s)-${request_number}"

  if [ -n "$body" ]; then
    result=$(curl --silent --show-error \
      --output /dev/null \
      --request "$method" \
      --header "Content-Type: application/json" \
      --header "User-Agent: mockoon-traffic-generator/1.0" \
      --header "X-Traffic-Generator-ID: $request_id" \
      --data "$body" \
      --write-out "status=%{http_code} duration=%{time_total}s" \
      "$BASE_URL$path" 2>&1)
  else
    result=$(curl --silent --show-error \
      --output /dev/null \
      --request "$method" \
      --header "User-Agent: mockoon-traffic-generator/1.0" \
      --header "X-Traffic-Generator-ID: $request_id" \
      --write-out "status=%{http_code} duration=%{time_total}s" \
      "$BASE_URL$path" 2>&1)
  fi
  curl_status=$?

  if [ "$curl_status" -eq 0 ]; then
    printf '%s method=%s path=%s %s request_id=%s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$method" "$path" "$result" "$request_id"
  else
    printf '%s method=%s path=%s error=%s request_id=%s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$method" "$path" "$result" "$request_id" >&2
  fi
}

trap 'echo "Stopping traffic generator"; exit 0' INT TERM

echo "Generating traffic against $BASE_URL every $INTERVAL_SECONDS seconds"

while true; do
  request GET /health
  sleep "$INTERVAL_SECONDS"
  request GET /users
  sleep "$INTERVAL_SECONDS"
  request GET /users/1
  sleep "$INTERVAL_SECONDS"
  request POST /users '{"name":"Traffic Generator","email":"traffic@example.com"}'
  sleep "$INTERVAL_SECONDS"
  request GET /errors/500
  sleep "$INTERVAL_SECONDS"
  request GET /slow
  sleep "$INTERVAL_SECONDS"
done
