FROM public.ecr.aws/lambda/python:3.11

# Override Lambda entrypoint
ENTRYPOINT [""]

# Install system dependencies
RUN yum install -y gcc-c++ python3.11-devel zip

# Create layer structure
RUN mkdir -p /lambda_layer/python/lib/python3.11/site-packages

# Copy requirements
COPY lambda-functions/verify_fingerprint/requirements.txt /tmp/

# Install Python dependencies
RUN pip install \
    --no-cache-dir \
    --upgrade \
    --target /lambda_layer/python/lib/python3.11/site-packages \
    -r /tmp/requirements.txt

# Package the layer
RUN cd /lambda_layer && zip -r layer.zip python

# Output
CMD cp /lambda_layer/layer.zip /output/