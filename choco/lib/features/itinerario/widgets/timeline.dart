class TimelineItem extends StatelessWidget {
  final ItemItinerario item;

  const TimelineItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = getEstadoColor(item.estado);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⏱️ Columna izquierda (hora + línea)
        SizedBox(
          width: 70,
          child: Column(
            children: [
              Text(
                _formatHora(item.inicio),
                style: const TextStyle(fontSize: 12),
              ),
              Container(
                width: 2,
                height: 80,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),

        // 🔴 Punto
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        // 📦 Card
        Expanded(
          child: ItemWidget(item: item),
        ),
      ],
    );
  }

  String _formatHora(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}