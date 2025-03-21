#!/bin/bash
set -eou pipefail

# Script to verify the numpy version in layer.zip
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." >/dev/null; pwd -P)
LAYER_FILE="$PROJECT_ROOT/lambda_layer/layer.zip"
TEMP_DIR="$PROJECT_ROOT/temp_layer"

cleanup() {
    rm -rf "$TEMP_DIR"
}

# Register cleanup function to run on script exit
trap cleanup EXIT

# Verify layer.zip exists
if [ ! -f "$LAYER_FILE" ]; then
    echo "❌ Error: Layer file not found at $LAYER_FILE"
    exit 1
fi

# Run verification in the Lambda Python 3.11 container
docker run --rm --entrypoint="" \
  -v "$PROJECT_ROOT:/workspace" \
  public.ecr.aws/lambda/python:3.11 \
  bash -c "yum install -y unzip >/dev/null 2>&1 && \
    unzip -q /workspace/lambda_layer/layer.zip -d /tmp/layer && \
    PYTHONPATH=/tmp/layer/python/lib/python3.11/site-packages \
    python3.11 -c 'import numpy; print(f\"✅ Numpy version: {numpy.__version__}\")'"

# Clean up temp files
cleanup