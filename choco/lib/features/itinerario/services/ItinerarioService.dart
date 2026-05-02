import 'dart:convert';

import 'package:choco/features/itinerario/models/Itinerario.dart';
import 'package:choco/core/mock/itinerario_mock.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ItinerarioService {
  String? get _baseUrl {
    final u = dotenv.maybeGet('API_BASE_URL') ?? dotenv.maybeGet('BACKEND_URL');
    if (u == null || u.isEmpty || u.contains('TU_BACKEND')) return null;
    var s = u.trim();
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  Future<Itinerario> getItinerario(int id) async {
    final base = _baseUrl;
    if (base != null) {
      try {
        final response = await http.get(Uri.parse('$base/itinerarios/$id'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Itinerario.fromJson(data);
        }
      } catch (_) {
        // Mock local para web / sin backend
      }
    }
    return Itinerario.fromJson(Map<String, dynamic>.from(itinerarioMock));
  }
}