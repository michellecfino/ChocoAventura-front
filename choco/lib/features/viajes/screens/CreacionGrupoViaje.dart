import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:choco/features/viajes/widgets/calendario.dart';

class CreacionGrupoViaje extends StatefulWidget {
  const CreacionGrupoViaje({super.key});

  @override
  State<CreacionGrupoViaje> createState() => _CreacionGrupoViajeState();
}

class _CreacionGrupoViajeState extends State<CreacionGrupoViaje> {
  final _formKey = GlobalKey<FormState>();

  bool get _mapsActivos {
    final clave = dotenv.maybeGet('GOOGLE_MAPS_API_KEY');
    return clave != null && clave.trim().isNotEmpty;
  }

  //  Datos
  String? nombre;
  String? descripcion;

  String? ciudad;
  String? pais;
  double? lat;
  double? lng;

  DateTime? fechaInicio;
  DateTime? fechaFin;
  TimeOfDay? horaLlegada;
  TimeOfDay? horaSalida;

  List<TimeOfDay> generarHoras() {
    return List.generate(24, (index) {
      return TimeOfDay(hour: index, minute: 0);
    });
  }

  DateTime combinarFechaYHora(DateTime fecha, TimeOfDay hora) {
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  TimeOfDay? horaAlmuerzo;
  TimeOfDay? horaInicio;

  int? tiempoAlmuerzo;

  final ciudadController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Grupo")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            //  Nombre
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Nombre del grupo",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? "Obligatorio" : null,
              onSaved: (v) => nombre = v,
            ),

            const SizedBox(height: 16),

            //  Descripción
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (v) => descripcion = v,
            ),

            const SizedBox(height: 16),

            if (_mapsActivos) ...[
              GooglePlaceAutoCompleteTextField(
                textEditingController: ciudadController,
                googleAPIKey: dotenv.maybeGet('GOOGLE_MAPS_API_KEY') ?? '',

                inputDecoration: const InputDecoration(
                  hintText: "Buscar ciudad",
                  border: OutlineInputBorder(),
                ),

                debounceTime: 800,
                isLatLngRequired: true,

                getPlaceDetailWithLatLng: (prediction) {
                  lat = double.tryParse(prediction.lat ?? "");
                  lng = double.tryParse(prediction.lng ?? "");
                },

                itemClick: (prediction) {
                  ciudadController.text = prediction.description ?? "";

                  final partes = (prediction.description ?? "").split(",");

                  ciudad = partes.first.trim();
                  pais = partes.last.trim();

                  setState(() {});
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Mapa desactivado temporalmente. Por ahora estamos preparando esta sección sin Google Maps.\n'
                  'Escribe ciudad y país manualmente.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Indica la ciudad' : null,
                onSaved: (v) => ciudad = v?.trim(),
                onChanged: (v) => ciudad = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'País',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Indica el país' : null,
                onSaved: (v) => pais = v?.trim(),
                onChanged: (v) => pais = v.trim(),
              ),
            ],

            const SizedBox(height: 8),

            Text(
              pais != null ? "País: $pais" : "Selecciona una ciudad válida",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            //  FECHAS
            DateRangePicker(
              onDateSelected: (start, end) {
                fechaInicio = start;
                fechaFin = end;
              },
            ),

            const SizedBox(height: 20),

            SizedBox(height: 20),

            //  HORA LLEGADA
            DropdownButtonFormField<TimeOfDay>(
              decoration: const InputDecoration(
                labelText: "Hora de llegada",
                border: OutlineInputBorder(),
              ),
              items: generarHoras().map((hora) {
                return DropdownMenuItem(
                  value: hora,
                  child: Text(hora.format(context)),
                );
              }).toList(),
              onChanged: (value) => setState(() => horaLlegada = value),
            ),

            SizedBox(height: 16),

            //  HORA SALIDA
            DropdownButtonFormField<TimeOfDay>(
              decoration: const InputDecoration(
                labelText: "Hora de salida",
                border: OutlineInputBorder(),
              ),
              items: generarHoras().map((hora) {
                return DropdownMenuItem(
                  value: hora,
                  child: Text(hora.format(context)),
                );
              }).toList(),
              onChanged: (value) => setState(() => horaSalida = value),
            ),

            SizedBox(height: 16),

            //  HORA ALMUERZO
            DropdownButtonFormField<TimeOfDay>(
              decoration: const InputDecoration(
                labelText: "Hora de almuerzo",
                border: OutlineInputBorder(),
              ),
              items: List.generate(24, (hour) {
                return DropdownMenuItem(
                  value: TimeOfDay(hour: hour, minute: 0),
                  child: Text("${hour.toString().padLeft(2, '0')}:00"),
                );
              }),
              onChanged: (v) => setState(() => horaAlmuerzo = v),
              validator: (v) => v == null ? "Selecciona hora" : null,
            ),

            const SizedBox(height: 16),

            //  HORA INICIO ACTIVIDADES
            DropdownButtonFormField<TimeOfDay>(
              decoration: const InputDecoration(
                labelText: "Inicio de actividades",
                border: OutlineInputBorder(),
              ),
              items: List.generate(24, (hour) {
                return DropdownMenuItem(
                  value: TimeOfDay(hour: hour, minute: 0),
                  child: Text("${hour.toString().padLeft(2, '0')}:00"),
                );
              }),
              onChanged: (v) => setState(() => horaInicio = v),
              validator: (v) => v == null ? "Selecciona hora" : null,
            ),

            const SizedBox(height: 16),

            //  DURACIÓN ALMUERZO
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Duración almuerzo",
                border: OutlineInputBorder(),
              ),
              items: List.generate(6, (i) {
                int min = (i + 1) * 30;
                return DropdownMenuItem(
                  value: min,
                  child: Text(
                    min < 60
                        ? "$min min"
                        : "${min ~/ 60}h ${min % 60 == 0 ? "" : "${min % 60}min"}",
                  ),
                );
              }),
              onChanged: (v) => setState(() => tiempoAlmuerzo = v),
              validator: (v) => v == null ? "Selecciona duración" : null,
            ),

            const SizedBox(height: 24),

            //  BOTÓN
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                if (ciudad == null || pais == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Selecciona una ciudad válida"),
                    ),
                  );
                  return;
                }

                if (fechaInicio == null || fechaFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Selecciona fechas")),
                  );
                  return;
                }

                if (fechaInicio == null || fechaFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Selecciona fechas")),
                  );
                  return;
                }

                if (horaLlegada == null || horaSalida == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Selecciona horas")),
                  );
                  return;
                }

                DateTime fechaInicioCompleta = combinarFechaYHora(
                  fechaInicio!,
                  horaLlegada!,
                );

                DateTime fechaFinCompleta = combinarFechaYHora(
                  fechaFin!,
                  horaSalida!,
                );

                _formKey.currentState!.save();

                print(nombre);
                print(ciudad);
                print(pais);
                print(fechaInicioCompleta);
                print(fechaFinCompleta);
                print(horaAlmuerzo);

                // Payload listo para integrar con POST crear grupo (nombre, ciudad, fechas, horarios…)
                // Aqui se llama al back
              },
              child: const Text("Crear Grupo"),
            ),
          ],
        ),
      ),
    );
  }
}
