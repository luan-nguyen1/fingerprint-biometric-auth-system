#!/bin/bash
set -e
cd "$(dirname "$0")"
cd ..

ZIP_FILE="lambda_function.zip"

if [ -d "package" ]; then
    rm -rf package
fi

if [ -f "$ZIP_FILE" ]; then
    rm -f "$ZIP_FILE"
fi

mkdir -p package

echo "Copying source files into 'package'..."
cp lambda-functions/verify_fingerprint/lambda_function.py package/
cp lambda-functions/verify_fingerprint/fingerprint_matching.py package/

cd package
zip -r ../"$ZIP_FILE" .
cd ..

echo "Package created: $ZIP_FILE"
