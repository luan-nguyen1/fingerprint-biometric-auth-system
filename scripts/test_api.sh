#!/bin/bash

# Encode sample image to base64 (compatible with macOS)
BASE64_IMAGE=$(cat DB1_B/101_1.tif | base64 | tr -d '\n')

# Call API
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"fingerprint_image\": \"${BASE64_IMAGE}\", \"user_id\": \"user_001\"}" \
  https://2o2i3qgn8j.execute-api.eu-central-1.amazonaws.com/dev/verify-fingerprint