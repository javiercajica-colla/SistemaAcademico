import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/piar_provider.dart';
import 'piar_alertas_view.dart';
import 'piar_avales_view.dart';
import 'piar_detail_view.dart';
import 'piar_list_view.dart';

/// Pantalla PIAR del coordinador: alterna entre el listado de
/// inscripciones (con su detalle) y la bandeja de avales, sin cambiar de
/// ruta (mismo patrón que otras pantallas del sistema con estado interno
/// de "vista seleccionada", ej. CoursesScreen).
class PiarScreen extends StatefulWidget {
  const PiarScreen({super.key});

  @override
  State<PiarScreen> createState() => _PiarScreenState();
}

class _PiarScreenState extends State<PiarScreen> {
  String? _inscripcionSeleccionadaId;
  int _tab = 0;

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

    final piar = context.watch<PiarProvider>();
    final pendientesAval = piar.ajustesPendientesDeAval.length;
    final alertasAbiertas = piar.alertasAbiertas.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              _TabButton(
                label: 'Inscripciones',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Bandeja de avales',
                selected: _tab == 1,
                badge: pendientesAval > 0 ? pendientesAval : null,
                onTap: () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Alertas',
                selected: _tab == 2,
                badge: alertasAbiertas > 0 ? alertasAbiertas : null,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (_tab) {
            0 => PiarListView(onAbrirDetalle: _abrirDetalle),
            1 => const PiarAvalesView(),
            _ => PiarAlertasView(onAbrirInscripcion: _abrirDetalle),
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.coordinator : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.coordinator : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
