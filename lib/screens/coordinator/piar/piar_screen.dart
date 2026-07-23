import 'package:flutter/material.dart';

import 'piar_detail_view.dart';
import 'piar_list_view.dart';

/// Pantalla PIAR del coordinador: alterna entre el listado de
/// inscripciones y el detalle de una inscripción concreta, sin cambiar de
/// ruta (mismo patrón que otras pantallas del sistema con estado interno
/// de "vista seleccionada", ej. CoursesScreen).
class PiarScreen extends StatefulWidget {
  const PiarScreen({super.key});

  @override
  State<PiarScreen> createState() => _PiarScreenState();
}

class _PiarScreenState extends State<PiarScreen> {
  String? _inscripcionSeleccionadaId;

  void _abrirDetalle(String inscripcionId) {
    setState(() => _inscripcionSeleccionadaId = inscripcionId);
  }

  void _volverAlListado() {
    setState(() => _inscripcionSeleccionadaId = null);
  }

  @override
  Widget build(BuildContext context) {
    final id = _inscripcionSeleccionadaId;
    if (id != null) {
      return PiarDetailView(inscripcionId: id, onVolver: _volverAlListado);
    }
    return PiarListView(onAbrirDetalle: _abrirDetalle);
  }
}
