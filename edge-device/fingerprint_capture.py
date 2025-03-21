import requests
import base64

# Načtení obrázku fingerprintu (první vzorek)
with open('fingerprints_dataset/sample_fingerprint.png', 'rb') as img_file:
    fingerprint_encoded = base64.b64encode(img_file.read()).decode('utf-8')

# URL endpointu, zatím placeholder (později AWS)
url = "https://your-api-gateway-endpoint.com/verify-fingerprint"

# Simulace HTTPS POST
response = requests.post(url, json={
    'fingerprint_image': fingerprint_encoded,
    'user_id': 'user_001'
})

print(response.status_code, response.json())
