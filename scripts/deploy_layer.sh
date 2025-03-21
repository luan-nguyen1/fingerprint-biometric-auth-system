#!/bin/bash

set -e

LAYER_NAME="fingerprint-layer"
ZIP_PATH="lambda_layer/layer.zip"
RUNTIME="python3.11"
REGION="eu-central-1"

echo "🔍 Checking for layer ZIP file..."
if [ ! -f "$ZIP_PATH" ]; then
    echo "❌ Error: $ZIP_PATH not found."
    exit 1
fi

echo "⬆️ Publishing new Lambda layer version..."
PUBLISH_OUTPUT=$(aws lambda publish-layer-version \
    --layer-name "$LAYER_NAME" \
    --zip-file "fileb://$ZIP_PATH" \
    --compatible-runtimes "$RUNTIME" \
    --region "$REGION")

LAYER_VERSION_ARN=$(echo "$PUBLISH_OUTPUT" | jq -r '.LayerVersionArn')

echo "✅ Layer published successfully:"
echo "$LAYER_VERSION_ARN"
