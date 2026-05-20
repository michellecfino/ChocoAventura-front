import 'package:choco/app/colors.dart';
import 'package:choco/features/viajes/models/UnirseGrupoDTO.dart';
import 'package:choco/features/viajes/models/categoria.dart';
import 'package:choco/features/viajes/services/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CrearPerfilScreen extends StatefulWidget {
  final int usuarioId;
  final int grupoViajeId;

  const CrearPerfilScreen({
    super.key,
    required this.usuarioId,
    required this.grupoViajeId,
  });

  @override
  State<CrearPerfilScreen> createState() => _CrearPerfilScreenState();
}

class _CrearPerfilScreenState extends State<CrearPerfilScreen> {
  final TextEditingController presupuestoController = TextEditingController();
  final TextEditingController personasController = TextEditingController();

  bool viajaConPersonas = false;
  int categoriasVisibles = 10;

  List<Categoria> categorias = [];
  List<int> categoriasSeleccionadas = [];

  late Future<List<Categoria>> futureCategorias;

  @override
  void initState() {
    super.initState();
    futureCategorias = ViajesService().getCategorias();
  }
    void enviar() async {
    if (presupuestoController.text.isEmpty) {
      mostrarError("Debes ingresar presupuesto");
      return;
    }

    if (viajaConPersonas && personasController.text.isEmpty) {
      mostrarError("Debes indicar personas a cargo");
      return;
    }

    double presupuesto = double.parse(presupuestoController.text);
    int personas = viajaConPersonas
        ? int.parse(personasController.text)
        : 1;

    // ⚠️ lógica interna (no visible)
    double presupuestoFinal = presupuesto / personas;

    if (categoriasSeleccionadas.isEmpty) {
      bool continuar = await mostrarConfirmacion();
      if (!continuar) return;
    }

    final dto = UnirseGrupoDTO(
      usuarioId: widget.usuarioId,
      grupoId: widget.grupoViajeId,
      categoriasIds: categoriasSeleccionadas,
      presupuesto: presupuestoFinal,
      personasACargo: personas,
    );

    await ViajesService().unirseAGrupo(dto);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usuario unido correctamente")),
    );
  }

    void mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<bool> mostrarConfirmacion() async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("¿Continuar sin categorías?"),
            content: const Text("No seleccionaste ninguna categoría"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sí"),
              ),
            ],
          ),
        ) ??
        false;
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Crear Perfil",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<List<Categoria>>(
        future: futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error cargando categorías"));
          }

          categorias = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Presupuesto
                Text("Presupuesto", style: titulo()),
                TextField(
                  controller: presupuestoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Ej: 1500.0",
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Pregunta
                Text("¿Pagas por alguien más?", style: titulo()),

                Row(
                  children: [
                    Checkbox(
                      value: viajaConPersonas,
                      onChanged: (value) {
                        setState(() {
                          viajaConPersonas = value!;
                        });
                      },
                    ),
                    const Text("Sí"),
                  ],
                ),

                if (viajaConPersonas)
                  TextField(
                    controller: personasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Número de personas que cubres",
                    ),
                  ),

                const SizedBox(height: 20),

                // 🔹 Preferencias
                Text("Preferencias", style: titulo()),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: categorias.map((cat) {
                    final selected =
                        categoriasSeleccionadas.contains(cat.id);

                    return ChoiceChip(
                      label: Text(cat.nombre),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            categoriasSeleccionadas.remove(cat.id);
                          } else {
                            categoriasSeleccionadas.add(cat.id);
                          }
                        });
                      },
                      selectedColor: AppColors.accent,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

if (categorias.length > 10)
  Center(
    child: TextButton(
      onPressed: () {
        setState(() {
          if (categoriasVisibles < categorias.length) {
            categoriasVisibles += 10;
            if (categoriasVisibles > categorias.length) {
              categoriasVisibles = categorias.length;
            }
          } else {
            categoriasVisibles -= 10;
            if (categoriasVisibles < 10) {
              categoriasVisibles = 10;
            }
          }
        });
      },
      child: Text(
        categoriasVisibles < categorias.length
            ? "Show more"
            : "Show less",
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),   

                const SizedBox(height: 30),

                // 🔹 Botón
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Iniciar Swipe"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextStyle titulo() {
    return GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    );
  }
}