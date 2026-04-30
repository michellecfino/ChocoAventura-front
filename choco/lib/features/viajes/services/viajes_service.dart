import 'package:choco/features/viajes/models/UnirseGrupoDTO.dart';
import 'package:choco/features/viajes/models/categoria.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ViajesService {
  const ViajesService();

  Future<void> crearViaje() async {
    // Luego aquí irá el POST para crear grupo viaje.
  }

  Future<void> cargarViajesUsuario() async {
    // Luego aquí irá la carga de viajes del usuario.
  }
  Future<List<Categoria>> getCategorias() async {
  final response = await http.get(
    Uri.parse('http://tu-api.com/categorias'),
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return categoriasFromJson(data);
  } else {
    throw Exception('Error al cargar categorías');
  }
  }

  Future<String> unirseAGrupo(UnirseGrupoDTO dto) async {
  final response = await http.post(
    Uri.parse('http://tu-api.com/unirse'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(dto.toJson()),
  );

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Error al unirse');
  }
  }

  List<Categoria> categoriasFromJson(List<dynamic> jsonList) {
  return jsonList
      .map((json) => Categoria.fromJson(json))
      .toList();
  }
}