import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:choco/features/viajes/widgets/calendario.dart';

class CreacionGrupoViaje extends StatefulWidget {
  // 1. NUEVO: Variable para recibir los datos del Asistente
  final Map<String, dynamic>? datosAsistente;

  const CreacionGrupoViaje({super.key, this.datosAsistente});

  @override
  State<CreacionGrupoViaje> createState() => _CreacionGrupoViajeState();
}

class _CreacionGrupoViajeState extends State<CreacionGrupoViaje> {
  final _formKey = GlobalKey<FormState>();

  // Datos
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
  TimeOfDay? horaAlmuerzo;
  TimeOfDay? horaInicio;
  int? tiempoAlmuerzo;

  // 2. NUEVO: Controladores para pre-llenar los campos de texto
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final ciudadController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 3. NUEVO: Lógica para leer el JSON y pre-llenar el formulario
    if (widget.datosAsistente != null) {
      final datos = widget.datosAsistente!;

      if (datos['destination'] != null) {
        ciudadController.text = datos['destination'].toString();
        ciudad = datos['destination'].toString(); // Guardamos en la variable también
      }
      
      if (datos['tripName'] != null) {
        nombreController.text = datos['tripName'].toString();
        nombre = datos['tripName'].toString();
      }

      if (datos['description'] != null) {
        descripcionController.text = datos['description'].toString();
        descripcion = datos['description'].toString();
      }
    }
  }

  @override
  void dispose() {
    // Es buena práctica limpiar los controladores de memoria al cerrar la vista
    nombreController.dispose();
    descripcionController.dispose();
    ciudadController.dispose();
    super.dispose();
  }

  List<TimeOfDay> generarHoras() {
    return List.generate(24, (index) {
      return TimeOfDay(hour: index, minute: 0);
    });
  }

  DateTime combinarFechaYHora(DateTime fecha, TimeOfDay hora) {
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Grupo")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: nombreController, // Añadimos el controlador
              decoration: const InputDecoration(
                labelText: "Nombre del grupo",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? "Obligatorio" : null,
              onSaved: (v) => nombre = v,
            ),

            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: descripcionController, // Añadimos el controlador
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (v) => descripcion = v,
            ),

            const SizedBox(height: 16),

            // CIUDAD (GOOGLE)
            GooglePlaceAutoCompleteTextField(
              textEditingController: ciudadController,
              googleAPIKey: dotenv.get('GOOGLE_MAPS_API_KEY'),
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

            const SizedBox(height: 8),

            Text(
              pais != null ? "País: $pais" : "Selecciona una ciudad válida",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // FECHAS
            DateRangePicker(
              onDateSelected: (start, end) {
                fechaInicio = start;
                fechaFin = end;
              },
            ),

            const SizedBox(height: 20),

            // HORA LLEGADA
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

            const SizedBox(height: 16),

            // HORA SALIDA
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

            const SizedBox(height: 16),

            // HORA ALMUERZO
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

            // HORA INICIO ACTIVIDADES
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

            // DURACIÓN ALMUERZO
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

            // BOTÓN
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                if (ciudad == null) {
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

                final dto = {
                  "nombre": nombreController.text, // Modificado para usar el controller
                  "descripcion": descripcionController.text, // Modificado para usar el controller
                  "nombreCiudad": ciudad,
                  "paisCiudad": pais,
                  "latCiudad": lat,
                  "lngCiudad": lng,
                  "fechaInicio": fechaInicioCompleta.toIso8601String(),
                  "fechaFin": fechaFinCompleta.toIso8601String(),
                  "horaAlmuerzo": horaAlmuerzo!.format(context),
                  "horaInicioActividades": horaInicio!.format(context),
                  "tiempoParaAlmorzar": tiempoAlmuerzo,
                };
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
