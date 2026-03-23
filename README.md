# ChocoAventura-front

Este repositorio contiene el frontend del proyecto **ChocoAventura**, una aplicación para planear viajes en grupo de forma colaborativa, organizada y sin fricción.

---

# Organización de `lib`

La carpeta `lib/` contiene todo el código principal de la aplicación Flutter.  
Se organiza en tres bloques principales: `app`, `core` y `features`.

---

## 1. App

Contiene la configuración global de la aplicación.

- `app.dart`: punto central de la app (MaterialApp, tema, pantalla inicial)
- `routes.dart`: definición de rutas y navegación entre pantallas
- `theme.dart`: configuración visual global (tipografías, estilos, botones)
- `colors.dart`: paleta de colores oficial del proyecto

Esta carpeta evita que `main.dart` crezca demasiado y centraliza la configuración global.

---

## 2. Core

Contiene elementos reutilizables que no pertenecen a una sola parte del negocio.

- `widgets/`: componentes reutilizables (botones, tarjetas, inputs, loaders)
- `services/`: lógica técnica compartida (por ejemplo cliente HTTP para el backend)
- `utils/`: funciones auxiliares (formateo de precios, fechas, validaciones, etc.)
- `mock/`: datos simulados para pruebas de UI mientras no se conecta el backend

La carpeta `mock/` permite desarrollar y probar pantallas sin depender del backend, manteniendo estos datos separados de las pantallas.

---

## 3. Features

Contiene la lógica del negocio, organizada por módulos del producto.

Cada feature representa una parte del flujo de la aplicación.

### Estructura interna de cada feature

Cada feature sigue la misma organización:

- `screens/`: pantallas completas (lo que el usuario ve como una vista)
- `widgets/`: componentes específicos de esa feature
- `models/`: estructuras de datos (lo que viene del backend o se manipula en frontend)
- `services/`: comunicación con backend o lógica asociada a esa feature

Esto permite mantener el código organizado y escalar fácilmente.

---

## Features del proyecto

### auth
Manejo de autenticación de usuarios.

Incluye:
- login
- registro

---

### home
Pantalla inicial y navegación principal.

Incluye:
- acceso a crear viaje
- acceso a viajes existentes
- exploración de destinos

---

### viajes
Gestión del viaje como entidad principal.

Incluye:
- creación de viaje
- unirse a viaje
- configuración base (fechas, destino)
- participantes

---

### actividades
Todo lo relacionado con descubrir y seleccionar actividades.

Incluye:
- exploración inicial
- exploración individual (swipe)
- resumen de actividades seleccionadas
- detalle de actividad

Se agrupa en una sola feature porque todo gira alrededor del mismo concepto:  
**descubrir y evaluar actividades**.

---

### coordinacion
Manejo de la toma de decisiones en grupo.

Incluye:
- exploración grupal
- agrupación de actividades similares
- subasta de tokens
- resultados por ronda

Se separa porque aquí cambia la lógica: pasa de decisiones individuales a decisiones grupales.

---

### itinerario
Construcción y visualización del plan final del viaje.

Incluye:
- selección final de actividades
- organización por días
- visualización tipo agenda o mapa

---

### presupuesto
Gestión económica del viaje.

Incluye:
- cálculo de presupuesto
- distribución de gastos
- control por usuario

---

## Notas importantes

- La app está diseñada para consumir datos desde el backend (Spring Boot).
- Mientras se desarrolla el frontend, se pueden usar datos simulados desde `core/mock/`.

---

## Paleta de colores

Definida en `app/colors.dart`:

- Fondo: `#F9E0BB`
- Primario: `#697235`
- Texto: `#794634`
- Acento: `#FFA840`

---

## Estructura general

```text
lib/
  main.dart

  app/
    app.dart
    routes.dart
    theme.dart
    colors.dart

  core/
    widgets/
    services/
    utils/
    mock/

  features/
    auth/
    home/
    viajes/
    actividades/
    coordinacion/
    itinerario/
    presupuesto/