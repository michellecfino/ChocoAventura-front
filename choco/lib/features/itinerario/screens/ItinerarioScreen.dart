class ItinerarioScreen extends StatefulWidget {
  final int itinerarioId;

  const ItinerarioScreen({super.key, required this.itinerarioId});

  @override
  State<ItinerarioScreen> createState() => _ItinerarioScreenState();
}

class _ItinerarioScreenState extends State<ItinerarioScreen> {
  late Future<Itinerario> itinerario;

  @override
  void initState() {
    super.initState();
    itinerario = ItinerarioService().getItinerario(widget.itinerarioId);
  }


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Itinerario")),
      body: FutureBuilder<Itinerario>(
        future: itinerario,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          }

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.dias.length,
            itemBuilder: (context, index) {
              final dia = data.dias[index];
              return DiaWidget(dia: dia);
            },
          );
        },
      ),
    );
  }
}