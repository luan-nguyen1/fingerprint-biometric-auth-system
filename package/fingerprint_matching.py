import cv2
import numpy as np

def match_fingerprints(image1_bytes, image2_bytes, threshold=10):
    # Načtení obrázků z byte streamu
    nparr1 = np.frombuffer(image1_bytes, np.uint8)
    img1 = cv2.imdecode(nparr1, cv2.IMREAD_GRAYSCALE)
    
    nparr2 = np.frombuffer(image2_bytes, np.uint8)
    img2 = cv2.imdecode(nparr2, cv2.IMREAD_GRAYSCALE)
    
    # Inicializace ORB detektoru
    orb = cv2.ORB_create()
    
    # Detekce klíčových bodů a výpočet descriptorů
    kp1, des1 = orb.detectAndCompute(img1, None)
    kp2, des2 = orb.detectAndCompute(img2, None)
    
    if des1 is None or des2 is None:
        return False, 0  # Pokud nebyly nalezeny žádné klíčové body
    
    # Použití BFMatcher s Hamming distancí
    bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
    matches = bf.match(des1, des2)
    
    # Seřazení podle vzdálenosti (nižší = lepší)
    matches = sorted(matches, key=lambda x: x.distance)
    
    # Vypočítáme průměrnou vzdálenost nebo počet shod
    good_matches = [m for m in matches if m.distance < 50]  # prahová hodnota můžeš ladit
    score = len(good_matches)
    
    # Pokud počet dobrých shod překročí prahovou hodnotu, považujeme otisky za shodné
    is_match = score > threshold
    return is_match, score
