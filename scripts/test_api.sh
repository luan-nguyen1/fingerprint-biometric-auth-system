#!/bin/bash

# Correct path to the fingerprint image
IMAGE_PATH="DB1_B/101_1.tif"

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
  echo "❌ Image not found at path: $IMAGE_PATH"
  exit 1
fi

# Encode sample image to base64 (macOS compatible)
BASE64_IMAGE=$(base64 -i "$IMAGE_PATH" | tr -d '\n')

# Call API
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"fingerprint_image\": \"${BASE64_IMAGE}\", \"user_id\": \"user_001\"}" \
  https://2o2i3qgn8j.execute-api.eu-central-1.amazonaws.com/dev/verify-fingerprint
