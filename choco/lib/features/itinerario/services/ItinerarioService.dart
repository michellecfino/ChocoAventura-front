import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Itinerario.dart';
class ItinerarioService {
  final String baseUrl = "http://TU_BACKEND/api";

  Future<Itinerario> getItinerario(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/itinerarios/$id'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Itinerario.fromJson(data);
    } else {
      throw Exception('Error cargando itinerario');
    }
  }
}