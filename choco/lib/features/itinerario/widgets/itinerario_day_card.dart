class DiaWidget extends StatelessWidget {
  final DiaItinerario dia;

  const DiaWidget({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fecha
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            "${dia.fecha.day}/${dia.fecha.month}/${dia.fecha.year}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Actividades
        ...dia.items.map((item) => ItemWidget(item: item)),
      ],
    );
  }
}
