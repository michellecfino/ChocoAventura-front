import 'package:flutter/material.dart';

class HomeActionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  const HomeActionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(subtitulo),
        onTap: onTap,
      ),
    );
  }
}