import os
import re
import time
import json
import requests
from io import BytesIO
from PIL import Image
import imagehash

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PEXELS_API_KEY = "QAbsPCF3IlhB33IZ2Q4e2nwSNOLJzRDSuIJu7fLrOOz0rSEWqZdYimPz"
PIXABAY_API_KEY = "55703636-27e6a04592b5c782940df93df"

CACHE_FILE = os.path.join(BASE_DIR, "cache_descargas.json")
HASH_FILE = os.path.join(BASE_DIR, "hashes_usados.json")

ACTIVIDADES = {
    "Bogota": [
        ("Tour gastronómico por La Candelaria", [
            "street food La Candelaria Bogota Colombia",
            "Colombian food Bogota market",
            "Bogota food tour",
        ]),
        ("Clase de cocina colombiana", [
            "Colombian cooking class",
            "Colombian cuisine cooking",
            "people cooking Colombian food",
        ]),
        ("Recorrido de arte urbano", [
            "Bogota graffiti tour",
            "La Candelaria Bogota graffiti",
            "Bogota street art Colombia",
        ]),
        ("Cata de café colombiano", [
            "Colombian coffee tasting",
            "specialty coffee Colombia",
            "coffee cupping Colombia",
        ]),
        ("Ciclovía en Bogotá", [
            "Bogota ciclovia bicycle",
            "Bogota cycling Colombia",
            "people biking Bogota",
        ]),
        ("Senderismo en cerros orientales", [
            "Bogota hiking mountains",
            "cerros orientales Bogota hiking",
            "hiking Bogota Colombia",
        ]),
        ("Tour nocturno de leyendas", [
            "La Candelaria Bogota night",
            "Bogota historic center night",
            "Bogota night walking tour",
        ]),
        ("Ruta fotográfica por el centro histórico", [
            "La Candelaria Bogota colorful street",
            "Bogota historic center Colombia",
            "Bogota colonial street",
        ]),
        ("Chocolate santafereño con queso", [
            "Colombian hot chocolate cheese",
            "chocolate con queso Colombia",
            "traditional Colombian hot chocolate",
        ]),
        ("Picnic en parque urbano", [
            "Bogota park picnic",
            "Simon Bolivar park Bogota",
            "urban picnic Colombia",
        ]),
        ("Visita a mercado local", [
            "Paloquemao market Bogota",
            "Bogota local market food",
            "Colombian market Bogota",
        ]),
        ("Tour de museos", [
            "Museo del Oro Bogota",
            "Bogota museum Colombia",
            "people museum Bogota",
        ]),
        ("Clase de baile latino", [
            "latin dance class Colombia",
            "salsa class Bogota",
            "people dancing salsa Colombia",
        ]),
        ("Teatro en vivo", [
            "Bogota theater Colombia",
            "Teatro Colon Bogota",
            "live theater Colombia",
        ]),
        ("Caminata cultural por La Candelaria", [
            "La Candelaria Bogota walking tour",
            "La Candelaria Bogota Colombia street",
            "Bogota cultural tour",
        ]),
        ("Experiencia de café de especialidad", [
            "specialty coffee Bogota",
            "barista coffee Colombia",
            "Colombian coffee experience",
        ]),
        ("Recorrido histórico guiado", [
            "Bogota historic walking tour",
            "La Candelaria guide Bogota",
            "Bogota colonial architecture",
        ]),
        ("Tour de comida callejera", [
            "Bogota street food Colombia",
            "Colombian street food",
            "arepas Bogota street food",
        ]),
        ("Atardecer desde mirador", [
            "Bogota sunset viewpoint",
            "Monserrate Bogota sunset",
            "Bogota skyline sunset",
        ]),
        ("Escapada a laguna cercana", [
            "Laguna de Guatavita Colombia",
            "Guatavita lake Colombia hiking",
            "Guatavita Colombia nature",
        ]),
    ],

    "Medellin": [
        ("Tour de transformación social", [
            "Comuna 13 Medellin tour",
            "Comuna 13 Medellin Colombia",
            "Medellin transformation tour",
        ]),
        ("Recorrido de grafiti", [
            "Comuna 13 graffiti Medellin",
            "Medellin graffiti tour",
            "Comuna 13 street art",
        ]),
        ("Viaje en metrocable", [
            "Medellin metrocable Colombia",
            "Metrocable Medellin view",
            "Medellin cable car",
        ]),
        ("Senderismo en parque natural", [
            "Parque Arvi Medellin hiking",
            "Medellin nature hiking",
            "Parque Arvi Colombia",
        ]),
        ("Clase de café especial", [
            "coffee tasting Medellin",
            "Colombian coffee class Medellin",
            "coffee cupping Colombia",
        ]),
        ("Ruta gastronómica paisa", [
            "bandeja paisa Medellin",
            "Medellin food tour",
            "Colombian paisa food",
        ]),
        ("Parapente cerca de Medellín", [
            "paragliding Medellin Colombia",
            "San Felix Medellin paragliding",
            "parapente Medellin",
        ]),
        ("Visita a finca cafetera", [
            "coffee farm Medellin Colombia",
            "Colombian coffee farm tour",
            "coffee plantation Colombia",
        ]),
        ("Clase de cocina antioqueña", [
            "Colombian cooking class Medellin",
            "Antioquia food cooking",
            "people cooking Colombian food",
        ]),
        ("Caminata urbana por barrios históricos", [
            "Medellin walking tour Colombia",
            "Medellin city walking",
            "Medellin urban tour",
        ]),
        ("Tour fotográfico urbano", [
            "Medellin street photography",
            "Medellin colorful street",
            "Medellin urban photography",
        ]),
        ("Clase de salsa", [
            "salsa class Medellin",
            "people dancing salsa Medellin",
            "latin dance class Colombia",
        ]),
        ("Show de música en vivo", [
            "live music Medellin Colombia",
            "Medellin nightlife live music",
            "Colombia live music",
        ]),
        ("Excursión a cascadas", [
            "waterfall near Medellin Colombia",
            "Medellin waterfall hike",
            "Colombia waterfall hiking",
        ]),
        ("Picnic en zona verde", [
            "Medellin park picnic",
            "Parque Arvi picnic",
            "Colombia picnic nature",
        ]),
        ("Mercado de diseño local", [
            "Medellin design market",
            "Medellin local market",
            "Colombian artisan market Medellin",
        ]),
        ("Atardecer desde terraza", [
            "Medellin rooftop sunset",
            "Medellin sunset view",
            "Medellin skyline sunset",
        ]),
        ("Recorrido nocturno por Provenza", [
            "Provenza Medellin night",
            "Medellin Provenza nightlife",
            "El Poblado Medellin night",
        ]),
        ("Escapada a pueblo cercano", [
            "Guatape Colombia colorful streets",
            "Guatape day trip Medellin",
            "Antioquia town Colombia",
        ]),
        ("Experiencia cultural local", [
            "Medellin cultural experience",
            "Medellin local culture",
            "Colombia cultural tour",
        ]),
    ],

    "Cartagena": [
        ("Tour gastronómico costeño", [
            "Cartagena Colombia food tour",
            "Cartagena street food",
            "Caribbean Colombian food Cartagena",
        ]),
        ("Clase de cocina cartagenera", [
            "Cartagena cooking class",
            "Colombian Caribbean cooking",
            "people cooking Cartagena Colombia",
        ]),
        ("Paseo en barco por la bahía", [
            "Cartagena Colombia boat tour",
            "Cartagena bay boat",
            "boat Cartagena Colombia",
        ]),
        ("Snorkel en islas", [
            "snorkeling Rosario Islands Cartagena",
            "snorkel Cartagena Colombia",
            "Rosario Islands snorkeling",
        ]),
        ("Island hopping", [
            "Rosario Islands Cartagena boat",
            "island hopping Cartagena Colombia",
            "Cartagena islands tour",
        ]),
        ("Atardecer en la muralla", [
            "Cartagena wall sunset",
            "Cartagena Colombia sunset wall",
            "Cartagena old city sunset",
        ]),
        ("Baile de champeta", [
            "champeta dance Cartagena",
            "Cartagena champeta Colombia",
            "people dancing Cartagena Colombia",
        ]),
        ("Tour nocturno de leyendas", [
            "Cartagena old city night",
            "Cartagena night walking tour",
            "Cartagena colonial night",
        ]),
        ("Ruta fotográfica colonial", [
            "Cartagena colorful colonial street",
            "Cartagena old city photography",
            "Cartagena Colombia colonial street",
        ]),
        ("Paseo en bicicleta por barrios históricos", [
            "Cartagena bike tour",
            "Getsemani Cartagena bicycle",
            "Cartagena Colombia cycling",
        ]),
        ("Kayak en manglares", [
            "Cartagena mangrove kayak",
            "kayak mangroves Colombia",
            "Cartagena Colombia kayak",
        ]),
        ("Paddleboard en el mar", [
            "paddleboard Cartagena Colombia",
            "stand up paddle Cartagena",
            "paddle board Caribbean sea",
        ]),
        ("Día de playa en Barú", [
            "Playa Blanca Baru Cartagena",
            "Baru beach Cartagena Colombia",
            "beach day Cartagena Colombia",
        ]),
        ("Cena frente al mar", [
            "Cartagena dinner by the sea",
            "Cartagena rooftop dinner",
            "Cartagena restaurant sea view",
        ]),
        ("Cócteles en terraza histórica", [
            "Cartagena rooftop cocktails",
            "Cartagena rooftop bar",
            "Cartagena terrace drinks",
        ]),
        ("Recorrido por plazas coloniales", [
            "Cartagena colonial plazas",
            "Cartagena old city square",
            "Cartagena historic plaza",
        ]),
        ("Degustación de dulces típicos", [
            "Cartagena palenqueras sweets",
            "Cartagena Colombian sweets",
            "dulces tipicos Cartagena",
        ]),
        ("Clase de baile caribeño", [
            "Cartagena salsa dance class",
            "Cartagena champeta dance class",
            "people dancing Cartagena Colombia",
        ]),
        ("Tour cultural por Getsemaní", [
            "Getsemani Cartagena street art",
            "Getsemani Cartagena Colombia colorful street",
            "Cartagena Getsemani walking tour",
        ]),
        ("Paseo en lancha", [
            "Cartagena Colombia boat trip",
            "Cartagena islands boat tour",
            "Rosario Islands boat Cartagena",
        ]),
    ],

    "Amazonas": [
        ("Navegación por el río Amazonas", [
            "Amazon river boat Colombia",
            "Leticia Amazonas boat river",
            "Amazonas Colombia river tour",
        ]),
        ("Avistamiento de delfines rosados", [
            "pink dolphins Amazon river",
            "Amazonas Colombia pink dolphin",
            "delfines rosados Amazonas Colombia",
        ]),
        ("Caminata guiada por la selva", [
            "Amazon jungle hike Colombia",
            "Leticia Amazonas jungle tour",
            "Amazon rainforest Colombia hiking",
        ]),
        ("Avistamiento de aves", [
            "Amazonas Colombia birdwatching",
            "Amazon rainforest birds Colombia",
            "bird watching Amazon jungle",
        ]),
        ("Visita a comunidad indígena", [
            "indigenous community Amazonas Colombia",
            "Amazonas Colombia indigenous tourism",
            "Leticia Amazonas indigenous community",
        ]),
        ("Recorrido nocturno de fauna", [
            "Amazon jungle night tour",
            "Amazonas Colombia night wildlife",
            "night walk Amazon rainforest",
        ]),
        ("Paseo en canoa", [
            "Amazonas Colombia canoe",
            "Amazon river canoe Colombia",
            "Leticia Amazonas canoe tour",
        ]),
        ("Kayak en aguas tranquilas", [
            "Amazonas Colombia kayak",
            "Amazon river kayak",
            "kayaking Amazon jungle",
        ]),
        ("Canopy en la selva", [
            "Amazon jungle canopy Colombia",
            "canopy zipline Amazon rainforest",
            "Tanimboca canopy Amazonas Colombia",
        ]),
        ("Puentes colgantes en la selva", [
            "Amazon jungle suspension bridge",
            "Tanimboca suspension bridge Amazonas",
            "puentes colgantes Amazonas Colombia",
        ]),
        ("Fotografía de naturaleza", [
            "Amazon rainforest nature photography",
            "Amazonas Colombia nature",
            "Amazon jungle wildlife photography",
        ]),
        ("Observación de monos", [
            "Isla de los Micos Amazonas Colombia",
            "monkeys Amazonas Colombia",
            "Amazon jungle monkeys Colombia",
        ]),
        ("Pesca artesanal con guía local", [
            "Amazon river fishing Colombia",
            "Amazonas Colombia fishing",
            "traditional fishing Amazon river",
        ]),
        ("Aprendizaje de plantas medicinales", [
            "Amazon medicinal plants Colombia",
            "Amazonas indigenous medicinal plants",
            "Amazon rainforest plants guide",
        ]),
        ("Comida típica amazónica", [
            "Amazonas Colombia typical food",
            "Leticia Amazonas food",
            "Amazonian cuisine Colombia",
        ]),
        ("Mercado local amazónico", [
            "Leticia Amazonas market",
            "Amazonas Colombia local market",
            "market Leticia Colombia",
        ]),
        ("Cruce de la triple frontera", [
            "Leticia Tabatinga Santa Rosa triple border",
            "triple frontera Amazonas Colombia",
            "Leticia Amazonas border",
        ]),
        ("Dormir en reserva natural", [
            "Amazonas Colombia eco lodge",
            "Amazon jungle lodge Colombia",
            "Leticia Amazonas nature reserve lodge",
        ]),
        ("Escuchar sonidos de la selva", [
            "Amazon jungle night Colombia",
            "Amazon rainforest night",
            "Amazonas Colombia jungle night",
        ]),
        ("Inmersión cultural con guías locales", [
            "Amazonas Colombia local guide",
            "Amazon indigenous guide Colombia",
            "Leticia Amazonas cultural tour",
        ]),
    ],

    "Cali": [
        ("Clase de salsa caleña", [
            "Cali Colombia salsa class",
            "salsa lesson Cali Colombia",
            "people dancing salsa Cali",
        ]),
        ("Show de salsa en vivo", [
            "Cali salsa show",
            "salsa live show Cali Colombia",
            "Delirio Cali salsa show",
        ]),
        ("Bailar salsa en discoteca local", [
            "Cali salsa club",
            "salsa dancing Cali Colombia",
            "Cali nightlife salsa",
        ]),
        ("Ruta gastronómica valluna", [
            "Cali Colombia food tour",
            "comida valluna Cali",
            "Cali typical food Colombia",
        ]),
        ("Probar lulada y cholado", [
            "lulada Cali Colombia",
            "cholado Cali Colombia",
            "Colombian cholado",
        ]),
        ("Senderismo en los Farallones", [
            "Farallones de Cali hiking",
            "Cali Colombia mountain hiking",
            "Farallones Cali nature",
        ]),
        ("Baño en río Pance", [
            "Rio Pance Cali Colombia",
            "Pance river Cali",
            "Cali river Pance",
        ]),
        ("Ruta de miradores", [
            "Cali Colombia viewpoint",
            "Cali sunset viewpoint",
            "Cristo Rey Cali view",
        ]),
        ("Clase de cocina valluna", [
            "Cali cooking class Colombia",
            "Colombian cooking class Cali",
            "Valle del Cauca food cooking",
        ]),
        ("Noche de música en vivo", [
            "Cali live music Colombia",
            "Cali nightlife live music",
            "music live Cali Colombia",
        ]),
        ("Sesión fotográfica urbana", [
            "Cali Colombia street photography",
            "Cali urban photography",
            "San Antonio Cali colorful street",
        ]),
        ("Recorrido de murales", [
            "Cali street art Colombia",
            "Cali murals Colombia",
            "urban art Cali Colombia",
        ]),
        ("Café de especialidad", [
            "specialty coffee Cali Colombia",
            "Cali coffee shop Colombia",
            "barista coffee Cali",
        ]),
        ("Picnic en zona verde", [
            "Cali Colombia picnic park",
            "Cali green park picnic",
            "picnic Colombia park",
        ]),
        ("Mercado local caleño", [
            "Galeria Alameda Cali",
            "Cali local market Colombia",
            "Cali food market",
        ]),
        ("Escapada al Kilómetro 18", [
            "Kilometro 18 Cali Colombia",
            "Cali Kilometro 18 nature",
            "Kilometro 18 Valle del Cauca",
        ]),
        ("Comida típica en galería local", [
            "Galeria Alameda Cali food",
            "Cali typical food market",
            "comida tipica Cali Colombia",
        ]),
        ("Clase de baile urbano", [
            "urban dance class Cali Colombia",
            "dance class Cali Colombia",
            "people dancing Cali Colombia",
        ]),
        ("Atardecer desde Cristo Rey", [
            "Cristo Rey Cali sunset",
            "Cristo Rey Cali Colombia view",
            "Cali sunset Cristo Rey",
        ]),
        ("Caminata cultural por San Antonio", [
            "San Antonio Cali walking tour",
            "San Antonio Cali Colombia street",
            "Cali cultural walking tour",
        ]),
    ],
}

PALABRAS_PROHIBIDAS = [
    "logo", "vector", "illustration", "drawing", "cartoon", "map",
    "icon", "banner", "poster", "flyer", "template", "background",
    "wallpaper", "mockup", "ai generated"
]

PALABRAS_CLAVE_DESTINO = {
    "Bogota": ["bogota", "bogotá", "candelaria", "monserrate", "guatavita", "paloquemao", "colombia"],
    "Medellin": ["medellin", "medellín", "comuna", "arvi", "arví", "guatape", "guatapé", "san felix", "colombia"],
    "Cartagena": ["cartagena", "getsemani", "getsemaní", "baru", "barú", "rosario", "muralla", "colombia"],
    "Amazonas": ["amazonas", "amazon", "leticia", "tanimboca", "selva", "jungle", "rainforest", "colombia"],
    "Cali": ["cali", "pance", "farallones", "cristo rey", "san antonio", "alameda", "colombia"],
}


def normalizar(texto):
    texto = str(texto or "").lower()
    reemplazos = {
        "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u",
        "ñ": "n"
    }
    for a, b in reemplazos.items():
        texto = texto.replace(a, b)
    return texto


def limpiar_nombre(nombre):
    nombre = re.sub(r'[\\/:*?"<>|]', "", nombre)
    nombre = re.sub(r"\s+", " ", nombre).strip()
    return nombre[:120]


def cargar_json(path, default):
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return default
    return default


def guardar_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def buscar_pixabay(query):
    url = "https://pixabay.com/api/"

    params = {
        "key": PIXABAY_API_KEY,
        "q": query,
        "image_type": "photo",
        "orientation": "vertical",
        "safesearch": "true",
        "per_page": 20,
        "lang": "en",
    }

    r = requests.get(url, params=params, timeout=25)

    if r.status_code == 429:
        print("Pixabay rate limit. Esperando 60 segundos...")
        time.sleep(60)
        return []

    r.raise_for_status()
    data = r.json()

    candidatos = []

    for h in data.get("hits", []):
        candidatos.append({
            "provider": "pixabay",
            "url": h.get("largeImageURL") or h.get("webformatURL"),
            "pageURL": h.get("pageURL", ""),
            "texto": h.get("tags", ""),
            "width": h.get("imageWidth", 0),
            "height": h.get("imageHeight", 0),
        })

    return candidatos


def buscar_pexels(query):
    url = "https://api.pexels.com/v1/search"

    headers = {
        "Authorization": PEXELS_API_KEY
    }

    params = {
        "query": query,
        "orientation": "portrait",
        "per_page": 15,
        "locale": "en-US",
    }

    r = requests.get(url, headers=headers, params=params, timeout=25)

    if r.status_code == 429:
        print("Pexels rate limit. Esperando 60 segundos...")
        time.sleep(60)
        return []

    r.raise_for_status()
    data = r.json()

    candidatos = []

    for p in data.get("photos", []):
        candidatos.append({
            "provider": "pexels",
            "url": p["src"].get("large2x") or p["src"].get("large") or p["src"].get("portrait"),
            "pageURL": p.get("url", ""),
            "texto": f"{p.get('alt', '')} {p.get('photographer', '')}",
            "width": p.get("width", 0),
            "height": p.get("height", 0),
        })

    return candidatos


def puntuar_candidato(candidato, destino, actividad, query):
    texto = normalizar(
        candidato.get("texto", "") + " " +
        candidato.get("pageURL", "") + " " +
        candidato.get("url", "") + " " +
        query
    )

    if any(normalizar(p) in texto for p in PALABRAS_PROHIBIDAS):
        return -999

    score = 0

    # Destino: muy importante.
    for palabra in PALABRAS_CLAVE_DESTINO[destino]:
        if normalizar(palabra) in texto:
            score += 35

    # Query exacta: importante.
    for palabra in re.findall(r"[A-Za-zÁÉÍÓÚáéíóúÑñ]{4,}", query):
        if normalizar(palabra) in texto:
            score += 8

    # Actividad: importante.
    for palabra in re.findall(r"[A-Za-zÁÉÍÓÚáéíóúÑñ]{4,}", actividad):
        if normalizar(palabra) in texto:
            score += 10

    width = candidato.get("width", 0)
    height = candidato.get("height", 0)

    if height > width:
        score += 20

    if height >= 1000:
        score += 10

    if candidato.get("provider") == "pixabay":
        score += 5

    return score


def descargar_imagen(url):
    r = requests.get(url, timeout=35)
    r.raise_for_status()
    img = Image.open(BytesIO(r.content)).convert("RGB")
    return img


def imagen_valida(img):
    w, h = img.size
    if w < 600 or h < 700:
        return False
    if h / w < 0.75:
        return False
    return True


def recortar_card_vertical(img):
    # Formato card 4:5, ideal para swipe/cards móviles.
    target_ratio = 4 / 5
    w, h = img.size
    current_ratio = w / h

    if current_ratio > target_ratio:
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        img = img.crop((left, 0, left + new_w, h))
    else:
        new_h = int(w / target_ratio)
        top = max((h - new_h) // 2, 0)
        img = img.crop((0, top, w, top + new_h))

    return img.resize((1080, 1350))


def buscar_mejor_imagen(destino, actividad, queries, hashes_usados):
    candidatos_finales = []

    for query in queries:
        queries_expandidas = [
            query,
            f"{query} {destino} Colombia",
            f"{query} travel activity Colombia",
        ]

        for q in queries_expandidas:
            print(f"  Query: {q}")

            candidatos = buscar_pixabay(q) + buscar_pexels(q)

            for c in candidatos:
                if not c.get("url"):
                    continue

                c["score"] = puntuar_candidato(c, destino, actividad, q)

            candidatos = sorted(candidatos, key=lambda x: x["score"], reverse=True)

            for c in candidatos[:8]:
                if c["score"] < 55:
                    continue

                try:
                    img = descargar_imagen(c["url"])

                    if not imagen_valida(img):
                        continue

                    h = str(imagehash.phash(img))
                    if h in hashes_usados:
                        continue

                    c["img"] = img
                    c["hash"] = h
                    candidatos_finales.append(c)

                except Exception:
                    continue

            if candidatos_finales:
                candidatos_finales.sort(key=lambda x: x["score"], reverse=True)
                return candidatos_finales[0]

            time.sleep(1)

    return None


def main():
    cache = cargar_json(CACHE_FILE, {})
    hashes_usados = set(cargar_json(HASH_FILE, []))

    print(f"Carpeta raíz: {BASE_DIR}")

    for destino, actividades in ACTIVIDADES.items():
        carpeta = os.path.join(BASE_DIR, destino)
        os.makedirs(carpeta, exist_ok=True)

        print(f"\n=== {destino} ===")

        for actividad, queries in actividades:
            archivo = limpiar_nombre(actividad) + ".jpg"
            ruta = os.path.join(carpeta, archivo)
            clave = f"{destino}::{actividad}"

            if os.path.exists(ruta):
                print(f"Ya existe, no se toca: {archivo}")
                continue

            print(f"Buscando: {actividad}")

            mejor = buscar_mejor_imagen(destino, actividad, queries, hashes_usados)

            if not mejor:
                print(f"No guardé nada para: {actividad}")
                continue

            img_card = recortar_card_vertical(mejor["img"])
            img_card.save(ruta, "JPEG", quality=92, optimize=True)

            hashes_usados.add(mejor["hash"])
            guardar_json(HASH_FILE, list(hashes_usados))

            cache[clave] = {
                "provider": mejor["provider"],
                "score": mejor["score"],
                "url": mejor["url"],
                "pageURL": mejor["pageURL"],
                "texto": mejor.get("texto", ""),
            }
            guardar_json(CACHE_FILE, cache)

            print(f"Guardada: {destino}/{archivo} | score={mejor['score']} | {mejor['provider']}")
            time.sleep(1.5)


if __name__ == "__main__":
    main()