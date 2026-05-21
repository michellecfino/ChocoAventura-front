class UnirseGrupoDTO {
  final int usuarioId;
  final int? grupoId;
  final String? codigoInvitacion;
  final List<int> categoriasIds;
  final double presupuesto;
  final int personasACargo;

  const UnirseGrupoDTO({
    required this.usuarioId,
    this.grupoId,
    this.codigoInvitacion,
    required this.categoriasIds,
    required this.presupuesto,
    this.personasACargo = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      "usuarioId": usuarioId,
      if (grupoId != null) "grupoId": grupoId,
      if (codigoInvitacion != null && codigoInvitacion!.trim().isNotEmpty)
        "codigoInvitacion": codigoInvitacion!.trim(),
      "categoriasIds": categoriasIds,
      "presupuesto": presupuesto,
      "personasACargo": personasACargo,
    };
  }
}
