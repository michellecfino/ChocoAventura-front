class UnirseGrupoDTO {
  final int usuarioId;
  final int grupoId;
  final List<int> categoriasIds;
  final double presupuesto;
  final int personasACargo;

  UnirseGrupoDTO({
    required this.usuarioId,
    required this.grupoId,
    required this.categoriasIds,
    required this.presupuesto,
    required this.personasACargo,
  });

  Map<String, dynamic> toJson() {
    return {
      "usuarioId": usuarioId,
      "grupoId": grupoId,
      "categoriasIds": categoriasIds,
      "presupuesto": presupuesto,
      "personasACargo": personasACargo,
    };
  }
}