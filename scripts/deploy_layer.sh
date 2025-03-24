#!/bin/bash

set -e

# Config
LAYER_NAME="fingerprint-layer"
ZIP_PATH="lambda_layer/layer.zip"
RUNTIME="python3.11"
REGION="eu-central-1"
LAMBDA_FUNCTION_NAME="verify_fingerprint"

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

echo "🔍 Getting existing Lambda layers..."
EXISTING_LAYERS=$(aws lambda get-function-configuration \
  --function-name "$LAMBDA_FUNCTION_NAME" \
  --region "$REGION" \
  --query 'Layers[*].Arn' \
  --output text)

# Remove old versions of the same layer
FILTERED_LAYERS=""
for layer in $EXISTING_LAYERS; do
    if [[ "$layer" != arn:aws:lambda:$REGION:*:layer:$LAYER_NAME:* ]]; then
        FILTERED_LAYERS+="$layer "
    fi
done

echo "🧩 Combining layers..."
ALL_LAYERS="$LAYER_VERSION_ARN $FILTERED_LAYERS"

echo "🔗 Attaching all layers to Lambda function..."
aws lambda update-function-configuration \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --layers $ALL_LAYERS \
    --region "$REGION"

echo "🎉 Layer updated successfully and combined with previous layers!"
