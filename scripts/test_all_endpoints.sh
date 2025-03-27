#!/bin/bash
set -euo pipefail

echo "🚀 Running full API test suite..."

API="https://a47hcdsuul.execute-api.eu-central-1.amazonaws.com/dev"
PASSPORT_NO="CZ1234567"
NAME="Alice Novak"
FINGERPRINT_PATH="DB1_B/101_1.tif"
FACE_IMAGE_PATH="tests/sample_face.jpg"
PASSPORT_IMAGE_PATH="tests/sample_passport.jpg"

# --- 1. REGISTER TRAVELER (multipart) ---
echo -e "\n🔹 1. POST /register-traveler"
curl -s -X POST "$API/register-traveler" \
  -F "passport_image=@$PASSPORT_IMAGE_PATH" \
  -F "fingerprint_image=@$FINGERPRINT_PATH" \
  | jq .

# --- 2. VERIFY FINGERPRINT (multipart + form) ---
echo -e "\n🔹 2. POST /verify-fingerprint"
curl -s -X POST "$API/verify-fingerprint" \
  -F "passport_no=$PASSPORT_NO" \
  -F "fingerprint_image=@$FINGERPRINT_PATH" \
  | jq .

# --- 3. EXTRACT FACE INFO ---
echo -e "\n🔹 3. POST /extract-face-info"
curl -s -X POST "$API/extract-face-info" \
  -F "face_image=@$FACE_IMAGE_PATH" \
  | jq .

# --- 4. BOARDING PASS ---
echo -e "\n🔹 4. POST /boarding-pass"
curl -s -X POST "$API/boarding-pass" \
  -H "Content-Type: application/json" \
  -d '{"qr_data": "XYZ1234567890"}' \
  | jq .

# --- 5. GLOBAL ENTRY CHECK ---
echo -e "\n🔹 5. POST /global-entry"
curl -s -X POST "$API/global-entry" \
  -H "Content-Type: application/json" \
  -d "{\"passport_no\": \"$PASSPORT_NO\"}" \
  | jq .

# --- 6. ANOMALY CHECK ---
echo -e "\n🔹 6. POST /anomaly-check"
curl -s -X POST "$API/anomaly-check" \
  -H "Content-Type: application/json" \
  -d '{"event_type": "login_attempt", "details": "multiple failures"}' \
  | jq .

# --- 7. ADMIN CONFIG ---
echo -e "\n🔹 7. POST /admin-config"
curl -s -X POST "$API/admin-config" \
  -H "Content-Type: application/json" \
  -d '{"maintenance_mode": true}' \
  | jq .

# --- 8. ACCESS LOGS ---
echo -e "\n🔹 8. POST /access-logs"
curl -s -X POST "$API/access-logs" \
  -H "Content-Type: application/json" \
  -d '{"query": "last24h"}' \
  | jq .

echo -e "\n✅ All API tests completed!"
