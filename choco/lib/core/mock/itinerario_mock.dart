const itinerarioMock = {
  "id": 1,
  "nombre": "Viaje a Chocó Aventura",
  "presupuestoPromedioPersona": 1200000,
  "dias": [
    {
      "fecha": "2026-04-10",
      "items": [
        {
          "id": 1,
          "inicioProgramado": "2026-04-10T09:00:00",
          "finProgramado": "2026-04-10T11:00:00",
          "estado": "COMPLETADA",
          "actividad": {
            "id": 101,
            "nombre": "Snorkel en el Arrecife",
            "descripcion": "Explora los vibrantes arrecifes de coral del Pacífico y nada junto a tortugas marinas y peces multicolores.",
            "costoPorPersona": 80000,
            "duracionMin": 120,
            "calificacionPromedio": 4.8,
            "vigenciaInicio": "2026-01-01",
            "vigenciaFin": "2026-12-31",
            "preciosDetallados": "Adultos: \$80.000 COP, Niños (menores de 12): \$60.000 COP. Incluye alquiler de equipo.",
            "fuente": "Agencia Chocó Submarino",
            "direccion": "Muelle Principal, Capurganá",
            "imagenes": [
              {
                "id": 1,
                "url": "https://www.dresseldivers.com/wp-content/uploads/best-snorkeling-from-shore-in-the-caribbean-3.jpg",
                "actividadId": 101
              }
            ]
          }
        },
        {
          "id": 2,
          "inicioProgramado": "2026-04-10T14:00:00",
          "finProgramado": "2026-04-10T16:30:00",
          "estado": "EN_CURSO",
          "actividad": {
            "id": 102,
            "nombre": "Caminata por la Selva",
            "descripcion": "Recorrido ecológico guiado por la selva húmeda tropical observando flora endémica, ranas venenosas y aves exóticas.",
            "costoPorPersona": 45000,
            "duracionMin": 150,
            "calificacionPromedio": 4.5,
            "vigenciaInicio": "2026-01-01",
            "vigenciaFin": "2026-12-31",
            "preciosDetallados": "\$45.000 COP tarifa única. Descuento del 10% para grupos de más de 5 personas.",
            "fuente": "Guías Nativos del Chocó",
            "direccion": "Reserva Natural El Cielo",
            "imagenes": [
              {
                "id": 2,
                "url": "https://www.dresseldivers.com/wp-content/uploads/best-snorkeling-from-shore-in-the-caribbean-3.jpg",
                "actividadId": 102
              }
            ]
          }
        }
      ]
    },
    {
      "fecha": "2026-04-11",
      "items": [
        {
          "id": 3,
          "inicioProgramado": "2026-04-11T10:00:00",
          "finProgramado": "2026-04-11T13:00:00",
          "estado": "PROGRAMADA",
          "actividad": {
            "id": 103,
            "nombre": "Avistamiento de Ballenas",
            "descripcion": "Tour en lancha rápida para el emocionante avistamiento de ballenas jorobadas que llegan al Pacífico colombiano a dar a luz.",
            "costoPorPersona": 150000,
            "duracionMin": 180,
            "calificacionPromedio": 4.9,
            "vigenciaInicio": "2026-06-01",
            "vigenciaFin": "2026-10-31",
            "preciosDetallados": "\$150.000 COP por persona. Incluye seguro fluvial y refrigerio.",
            "fuente": "Pacífico Tours Bahía Solano",
            "direccion": "Puerto Muelle Turístico de Bahía Solano",
            "imagenes": [
              {
                "id": 3,
                "url": "https://www.dresseldivers.com/wp-content/uploads/best-snorkeling-from-shore-in-the-caribbean-3.jpg",
                "actividadId": 103
              }
            ]
          }
        },
        {
          "id": 4,
          "inicioProgramado": "2026-04-11T16:00:00",
          "finProgramado": "2026-04-11T18:00:00",
          "estado": "PROGRAMADA",
          "actividad": {
            "id": 104,
            "nombre": "Cena frente al Mar",
            "descripcion": "Deliciosa cena romántica degustando la mejor gastronomía típica del pacífico (encocado de pescado, arroz con coco).",
            "costoPorPersona": 60000,
            "duracionMin": 120,
            "calificacionPromedio": 4.7,
            // A propósito omitimos vigencia, fuente y preciosDetallados para probar el null-safety
            "direccion": "Restaurante Sabores del Manglar",
            "imagenes": [
              {
                "id": 4,
                "url": "https://www.dresseldivers.com/wp-content/uploads/best-snorkeling-from-shore-in-the-caribbean-3.jpg",
                "actividadId": 104
              }
            ]
          }
        }
      ]
    }
  ]
};