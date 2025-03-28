#!/bin/bash

set -e

echo "🔧 Building combined Lambda layer..."

# Config
LAYER_DIR="lambda_layer/python"
REQUIREMENTS_FILE="lambda_layer/requirements.txt"
OUTPUT_ZIP="lambda_layer/layer.zip"

# Clean previous builds
echo "🧹 Cleaning previous layer..."
rm -rf "$LAYER_DIR"
rm -f "$OUTPUT_ZIP"

# Create structure
echo "📁 Creating directory..."
mkdir -p "$LAYER_DIR"

# Install dependencies optimized for Lambda (arm64)
echo "📦 Installing Python packages for ARM64..."
pip install \
  --platform manylinux2014_aarch64 \
  --implementation cp \
  --only-binary=:all: \
  --upgrade \
  --target "$LAYER_DIR" \
  -r "$REQUIREMENTS_FILE"

# Create zip
echo "🗜️ Zipping layer..."
cd lambda_layer
zip -r9 layer.zip python > /dev/null
cd ..

echo "✅ Done! Combined Lambda layer ready at: $OUTPUT_ZIP"
