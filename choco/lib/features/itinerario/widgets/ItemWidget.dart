class ItemWidget extends StatelessWidget {
  final ItemItinerario item;

  const ItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(item.actividad.nombre),
        subtitle: Text(
          "${_formatHora(item.inicio)} - ${_formatHora(item.fin)}",
        ),
        trailing: Text("\$${item.actividad.costo.toInt()}"),
      ),
    );
  }

  String _formatHora(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}