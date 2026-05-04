import os
import re
import time
import requests

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# 🔑 PEGA TU API KEY AQUÍ
PEXELS_API_KEY = "QAbsPCF3IlhB33IZ2Q4e2nwSNOLJzRDSuIJu7fLrOOz0rSEWqZdYimPz"

HEADERS = {
    "Authorization": PEXELS_API_KEY
}

DESTINOS = {
    "Bogota": [
        "Tour gastronómico por La Candelaria",
        "Clase de cocina colombiana",
        "Recorrido de arte urbano",
        "Cata de café colombiano",
        "Ciclovía en Bogotá",
        "Senderismo en cerros orientales",
        "Tour nocturno de leyendas",
        "Ruta fotográfica por el centro histórico",
        "Chocolate santafereño con queso",
        "Picnic en parque urbano",
        "Visita a mercado local",
        "Tour de museos",
        "Clase de baile latino",
        "Teatro en vivo",
        "Caminata cultural por La Candelaria",
        "Experiencia de café de especialidad",
        "Recorrido histórico guiado",
        "Tour de comida callejera",
        "Atardecer desde mirador",
        "Escapada a laguna cercana",
    ],
    "Medellin": [
        "Tour de transformación social",
        "Recorrido de grafiti",
        "Viaje en metrocable",
        "Senderismo en parque natural",
        "Clase de café especial",
        "Ruta gastronómica paisa",
        "Parapente cerca de Medellín",
        "Visita a finca cafetera",
        "Clase de cocina antioqueña",
        "Caminata urbana por barrios históricos",
        "Tour fotográfico urbano",
        "Clase de salsa",
        "Show de música en vivo",
        "Excursión a cascadas",
        "Picnic en zona verde",
        "Mercado de diseño local",
        "Atardecer desde terraza",
        "Recorrido nocturno por Provenza",
        "Escapada a pueblo cercano",
        "Experiencia cultural local",
    ],
    "Cartagena": [
        "Tour gastronómico costeño",
        "Clase de cocina cartagenera",
        "Paseo en barco por la bahía",
        "Snorkel en islas",
        "Island hopping",
        "Atardecer en la muralla",
        "Baile de champeta",
        "Tour nocturno de leyendas",
        "Ruta fotográfica colonial",
        "Paseo en bicicleta por barrios históricos",
        "Kayak en manglares",
        "Paddleboard en el mar",
        "Día de playa en Barú",
        "Cena frente al mar",
        "Cócteles en terraza histórica",
        "Recorrido por plazas coloniales",
        "Degustación de dulces típicos",
        "Clase de baile caribeño",
        "Tour cultural por Getsemaní",
        "Paseo en lancha",
    ],
    "Amazonas": [
        "Navegación por el río Amazonas",
        "Avistamiento de delfines rosados",
        "Caminata guiada por la selva",
        "Avistamiento de aves",
        "Visita a comunidad indígena",
        "Recorrido nocturno de fauna",
        "Paseo en canoa",
        "Kayak en aguas tranquilas",
        "Canopy en la selva",
        "Puentes colgantes en la selva",
        "Fotografía de naturaleza",
        "Observación de monos",
        "Pesca artesanal con guía local",
        "Aprendizaje de plantas medicinales",
        "Comida típica amazónica",
        "Mercado local amazónico",
        "Cruce de la triple frontera",
        "Dormir en reserva natural",
        "Escuchar sonidos de la selva",
        "Inmersión cultural con guías locales",
    ],
    "Cali": [
        "Clase de salsa caleña",
        "Show de salsa en vivo",
        "Bailar salsa en discoteca local",
        "Ruta gastronómica valluna",
        "Probar lulada y cholado",
        "Senderismo en los Farallones",
        "Baño en río Pance",
        "Ruta de miradores",
        "Clase de cocina valluna",
        "Noche de música en vivo",
        "Sesión fotográfica urbana",
        "Recorrido de murales",
        "Café de especialidad",
        "Picnic en zona verde",
        "Mercado local caleño",
        "Escapada al Kilómetro 18",
        "Comida típica en galería local",
        "Clase de baile urbano",
        "Atardecer desde Cristo Rey",
        "Caminata cultural por San Antonio",
    ],
}


def limpiar_nombre(nombre):
    nombre = re.sub(r'[\\/:*?"<>|]', "", nombre)
    nombre = re.sub(r"\s+", " ", nombre).strip()
    return nombre.title()


def buscar_imagen(actividad, destino):
    url = "https://api.pexels.com/v1/search"

    query = f"{actividad} {destino} Colombia"

    params = {
        "query": query,
        "orientation": "portrait",
        "per_page": 10
    }

    res = requests.get(url, headers=HEADERS, params=params)
    res.raise_for_status()

    data = res.json()
    fotos = data.get("photos", [])

    if not fotos:
        return None

    return fotos[0]["src"]["portrait"]


def descargar(url, path):
    img = requests.get(url)
    img.raise_for_status()

    with open(path, "wb") as f:
        f.write(img.content)


def main():
    for destino, actividades in DESTINOS.items():
        carpeta = os.path.join(BASE_DIR, destino)
        os.makedirs(carpeta, exist_ok=True)

        print(f"\n=== {destino} ===")

        for actividad in actividades:
            nombre = limpiar_nombre(actividad) + ".jpg"
            ruta = os.path.join(carpeta, nombre)

            if os.path.exists(ruta):
                print(f"Ya existe: {nombre}")
                continue

            try:
                print(f"Buscando: {actividad}")
                url = buscar_imagen(actividad, destino)

                if not url:
                    print("No encontrada")
                    continue

                descargar(url, ruta)
                print(f"Guardada: {nombre}")

                time.sleep(1)

            except Exception as e:
                print(f"Error: {e}")
                time.sleep(3)


if __name__ == "__main__":
    main()