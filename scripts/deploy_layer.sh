#!/bin/bash

set -e

# Variables
LAYER_NAME="fingerprint-layer"
ZIP_PATH="lambda_layer/layer.zip"
RUNTIME="python3.11"
REGION="eu-central-1"
LAMBDA_FUNCTION_NAME="verify_fingerprint"
ARCHITECTURE="arm64"

echo "🔍 Checking for layer ZIP file..."
if [ ! -f "$ZIP_PATH" ]; then
    echo "❌ Error: $ZIP_PATH not found."
    exit 1
fi

echo "⬆️ Publishing new Lambda layer version for $ARCHITECTURE..."
PUBLISH_OUTPUT=$(aws lambda publish-layer-version \
    --layer-name "$LAYER_NAME" \
    --zip-file "fileb://$ZIP_PATH" \
    --compatible-runtimes "$RUNTIME" \
    --compatible-architectures "$ARCHITECTURE" \
    --region "$REGION")

LAYER_VERSION_ARN=$(echo "$PUBLISH_OUTPUT" | jq -r '.LayerVersionArn')

echo "✅ Layer published successfully:"
echo "$LAYER_VERSION_ARN"

echo "🔗 Attaching layer to Lambda function: $LAMBDA_FUNCTION_NAME..."
aws lambda update-function-configuration \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --layers "$LAYER_VERSION_ARN" \
    --region "$REGION"

echo "🎉 Layer attached successfully to Lambda function with architecture: $ARCHITECTURE"

exit 0
