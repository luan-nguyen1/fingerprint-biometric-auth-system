#!/bin/bash
set -euo pipefail

# Usage check
if [ $# -lt 1 ]; then
  echo "❌ Usage: $0 <lambda_name> [--only-build]"
  exit 1
fi

LAMBDA_NAME="$1"
ONLY_BUILD="${2:-false}"
LAMBDA_DIR="lambda-functions/$LAMBDA_NAME"
ZIP_FILE="lambda_function.zip"

cd "$(dirname "$0")"
cd ..

# Clean previous builds
rm -rf package "$ZIP_FILE"

# Build package
mkdir -p package
echo "📦 Copying source files from $LAMBDA_DIR into package/..."
cp "$LAMBDA_DIR"/*.py package/

# Optional: install requirements
# if [ -f "$LAMBDA_DIR/requirements.txt" ]; then
#   pip install --target package -r "$LAMBDA_DIR/requirements.txt"
# fi

# Zip package
echo "🗜️  Creating ZIP archive..."
cd package
zip -qr ../"$ZIP_FILE" .
cd ..

# Move zip to lambda directory (so Terraform can use it)
mv "$ZIP_FILE" "$LAMBDA_DIR/"

echo "✅ Package created: $LAMBDA_DIR/$ZIP_FILE"

# Deploy or exit
if [[ "$ONLY_BUILD" == "--only-build" ]]; then
  echo "📦 Build-only mode enabled — skipping deploy."
  exit 0
fi

# Deploy to Lambda
echo "🚀 Deploying to AWS Lambda: $LAMBDA_NAME"
aws lambda update-function-code \
  --region eu-central-1 \
  --function-name "$LAMBDA_NAME" \
  --zip-file "fileb://$LAMBDA_DIR/$ZIP_FILE"

echo "✅ Lambda '$LAMBDA_NAME' deployed successfully!"
