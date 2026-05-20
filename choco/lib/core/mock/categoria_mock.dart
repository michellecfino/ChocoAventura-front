import 'package:choco/features/viajes/models/categoria.dart';

class CategoriaMock {
  static List<Categoria> getCategorias() {
    return [
      Categoria(id: 1, nombre: "Aventura", descripcion: "Actividades extremas"),
      Categoria(id: 2, nombre: "Cultura", descripcion: "Museos y tours"),
      Categoria(id: 3, nombre: "Gastronomía", descripcion: "Comida local"),
      Categoria(id: 4, nombre: "Naturaleza", descripcion: "Parques y paisajes"),
      Categoria(id: 5, nombre: "Fiesta", descripcion: "Vida nocturna"),
      Categoria(id: 6, nombre: "Relax", descripcion: "Spa y descanso"),
      Categoria(id: 7, nombre: "Deportes", descripcion: "Actividades deportivas"),
      Categoria(id: 8, nombre: "Compras", descripcion: "Centros comerciales"),
      Categoria(id: 9, nombre: "Historia", descripcion: "Sitios históricos"),
      Categoria(id: 10, nombre: "Tecnología", descripcion: "Experiencias tech"),
    ];
  }
}