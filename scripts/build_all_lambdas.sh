#!/bin/bash
set -e

# Absolutní cesta ke kořenu repozitáře
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy_lambda.sh"

LAMBDAS=(
  verify_fingerprint
  upload_documents
  extract_face_info
  traveler_history
  scan_boarding_pass
  check_global_entry
  anomaly_check
  config_admin
  access_logs
  generate_upload_url
  extract_passport_info
)

for fn in "${LAMBDAS[@]}"; do
  echo "📦 Building $fn"
  "$DEPLOY_SCRIPT" "$fn" --only-build
done

echo "✅ All Lambda ZIPs built successfully!"
