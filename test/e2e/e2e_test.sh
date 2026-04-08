#!/bin/bash
# ============================================================================
# e2e_test.sh — End-to-End Test for Dictionary Microservice
# ============================================================================
# Starts the server, exercises all endpoints via curl, verifies status
# codes and response bodies, then stops the server.
#
# Usage:
#   ./test/e2e/e2e_test.sh              (from project root)
#   make test-e2e                       (via Makefile)
#
# Exit code: 0 = all passed, 1 = failures
# ============================================================================

# No set -e: we track pass/fail manually.
# No set -o pipefail: background server kill would propagate 143.

PORT=8080
BINARY="./bin/dictionary_stdlib"
BASE="http://localhost:${PORT}"
PASS=0
FAIL=0
SERVER_PID=""

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
stop_server() {
   if [ -n "${SERVER_PID:-}" ]; then
      kill "$SERVER_PID" 2>/dev/null || true
      sleep 1
   fi
}

assert_status() {
   local test_name="$1"
   local expected="$2"
   local actual="$3"
   if [ "$actual" = "$expected" ]; then
      PASS=$((PASS + 1))
   else
      FAIL=$((FAIL + 1))
      echo "  FAIL: ${test_name} (expected ${expected}, got ${actual})"
   fi
}

assert_contains() {
   local test_name="$1"
   local body="$2"
   local substring="$3"
   if echo "$body" | grep -q "$substring"; then
      PASS=$((PASS + 1))
   else
      FAIL=$((FAIL + 1))
      echo "  FAIL: ${test_name} (body missing '${substring}')"
   fi
}

# Helper: curl returning body and status code
call() {
   local method="$1"
   local path="$2"
   local data="${3:-}"
   if [ -n "$data" ]; then
      curl -s -w "\n%{http_code}" -X "$method" "${BASE}${path}" -d "$data" 2>/dev/null
   else
      curl -s -w "\n%{http_code}" -X "$method" "${BASE}${path}" 2>/dev/null
   fi
}

parse_response() {
   # Last line is status code, everything else is body
   local raw="$1"
   BODY=$(echo "$raw" | sed '$d')
   STATUS=$(echo "$raw" | tail -1)
}

# ----------------------------------------------------------------------------
# Start server
# ----------------------------------------------------------------------------
echo "Dictionary E2E Tests"
echo "===================="
echo ""

if [ ! -f "$BINARY" ]; then
   echo "ERROR: Binary not found at ${BINARY}."
   echo "       Run 'make build' first."
   exit 1
fi

"$BINARY" > /dev/null 2>&1 &
SERVER_PID=$!
disown "$SERVER_PID"
sleep 1

# Verify server is up
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
   echo "ERROR: The server failed to start."
   exit 1
fi

echo "Server started (PID ${SERVER_PID}, port ${PORT})"
echo ""

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

echo "--- Health ---"
parse_response "$(call GET /health)"
assert_status "GET /health status" "200" "$STATUS"
assert_contains "GET /health body" "$BODY" "healthy"

echo "--- Create ---"
parse_response "$(call POST /entries '{"key":"hello","value":"A greeting"}')"
assert_status "POST create hello" "201" "$STATUS"
assert_contains "POST create body" "$BODY" "hello"

parse_response "$(call POST /entries '{"key":"world","value":"The planet"}')"
assert_status "POST create world" "201" "$STATUS"

parse_response "$(call POST /entries '{"key":"alpha","value":"First letter"}')"
assert_status "POST create alpha" "201" "$STATUS"

echo "--- Duplicate ---"
parse_response "$(call POST /entries '{"key":"hello","value":"dup"}')"
assert_status "POST duplicate" "409" "$STATUS"

parse_response "$(call POST /entries '{"key":"HELLO","value":"case dup"}')"
assert_status "POST case-insensitive dup" "409" "$STATUS"

echo "--- Get one ---"
parse_response "$(call GET /entries/hello)"
assert_status "GET hello" "200" "$STATUS"
assert_contains "GET hello body" "$BODY" "A greeting"

echo "--- Get missing ---"
parse_response "$(call GET /entries/missing)"
assert_status "GET missing" "404" "$STATUS"

echo "--- List (sorted) ---"
parse_response "$(call GET /entries)"
assert_status "GET /entries" "200" "$STATUS"
# Verify order: alpha appears before hello appears before world
assert_contains "list has alpha" "$BODY" "alpha"
assert_contains "list has hello" "$BODY" "hello"
assert_contains "list has world" "$BODY" "world"
# Verify actual sort order by checking substring positions.
ALPHA_POS=$(echo "$BODY" | grep -bo "alpha" | head -1 | cut -d: -f1)
HELLO_POS=$(echo "$BODY" | grep -bo "hello" | head -1 | cut -d: -f1)
WORLD_POS=$(echo "$BODY" | grep -bo "world" | head -1 | cut -d: -f1)
if [ "$ALPHA_POS" -lt "$HELLO_POS" ] && [ "$HELLO_POS" -lt "$WORLD_POS" ]; then
   PASS=$((PASS + 1))
else
   FAIL=$((FAIL + 1))
   echo "  FAIL: list sort order (alpha=$ALPHA_POS hello=$HELLO_POS world=$WORLD_POS)"
fi

echo "--- Update ---"
parse_response "$(call PUT /entries/hello '{"key":"hello","value":"Updated greeting"}')"
assert_status "PUT update hello" "200" "$STATUS"
assert_contains "PUT body" "$BODY" "Updated greeting"

parse_response "$(call GET /entries/hello)"
assert_contains "GET updated value" "$BODY" "Updated greeting"

echo "--- Update missing ---"
parse_response "$(call PUT /entries/nope '{"value":"x"}')"
assert_status "PUT missing" "404" "$STATUS"

echo "--- Update key mismatch ---"
parse_response "$(call PUT /entries/hello '{"key":"wrong","value":"x"}')"
assert_status "PUT key mismatch" "400" "$STATUS"

echo "--- Delete ---"
parse_response "$(call DELETE /entries/hello)"
assert_status "DELETE hello" "204" "$STATUS"

parse_response "$(call DELETE /entries/hello)"
assert_status "DELETE already deleted" "404" "$STATUS"

echo "--- Bad key ---"
parse_response "$(call GET "/entries/bad_key!")"
assert_status "GET bad key" "400" "$STATUS"

echo "--- Bad JSON ---"
parse_response "$(call POST /entries 'not json')"
assert_status "POST bad json" "400" "$STATUS"

echo "--- Method not allowed ---"
parse_response "$(call DELETE /entries)"
assert_status "DELETE /entries" "405" "$STATUS"

parse_response "$(call POST /entries/alpha)"
assert_status "POST /entries/{key}" "405" "$STATUS"

echo "--- Unknown path ---"
parse_response "$(call GET /unknown)"
assert_status "GET /unknown" "404" "$STATUS"

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
TOTAL=$((PASS + FAIL))
echo ""
echo "========================================"
echo "  Total: ${TOTAL}"
echo "  Pass:  ${PASS}"
echo "  Fail:  ${FAIL}"
echo "========================================"

stop_server

if [ "$FAIL" -eq 0 ]; then
   echo "  Result: ALL PASSED"
   echo "========================================"
   exit 0
else
   echo "  Result: FAILURES"
   echo "========================================"
   exit 1
fi
