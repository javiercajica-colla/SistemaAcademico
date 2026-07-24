import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/piar_models.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';

const _kTipoAlertaLabels = {
  PiarTipoAlerta.docenteSinAjustes: 'Docente sin responder',
  PiarTipoAlerta.aplicacionCompletaSinAvance: 'Aplicado sin avance',
  PiarTipoAlerta.noAplicadoRepetido: 'No aplicado varias veces',
  PiarTipoAlerta.logradoAutonomiaRepetido: 'Posible retiro del ajuste',
  PiarTipoAlerta.soporteVencido: 'Soporte externo vencido',
  PiarTipoAlerta.actaNoFirmada: 'Acta sin firmar',
};

const _kTipoAlertaIconos = {
  PiarTipoAlerta.docenteSinAjustes: Icons.hourglass_empty_rounded,
  PiarTipoAlerta.aplicacionCompletaSinAvance: Icons.trending_flat_rounded,
  PiarTipoAlerta.noAplicadoRepetido: Icons.block_rounded,
  PiarTipoAlerta.logradoAutonomiaRepetido: Icons.emoji_events_outlined,
  PiarTipoAlerta.soporteVencido: Icons.event_busy_rounded,
  PiarTipoAlerta.actaNoFirmada: Icons.assignment_late_outlined,
};

/// Alertas automáticas (Fase 8): el sistema las genera solo (ver
/// PiarProvider._revisarAlertasAutomaticas/_evaluarReglasDeSeguimiento),
/// coordinación solo las revisa y las marca como leídas — no hay
/// formulario de creación manual.
class PiarAlertasView extends StatelessWidget {
  const PiarAlertasView({super.key, required this.onAbrirInscripcion});

  final void Function(String inscripcionId) onAbrirInscripcion;

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    final alertas = piar.alertasAbiertas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          color: AppColors.surface,
          child: const SectionHeader(
            title: 'Alertas',
            subtitle:
                'Generadas automáticamente por el sistema a partir de los '
                'ajustes, seguimientos, soportes y actas del módulo PIAR.',
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: alertas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay alertas abiertas.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: alertas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AlertaCard(
                    alerta: alertas[i],
                    onAbrirInscripcion: onAbrirInscripcion,
                  ),
                ),
        ),
      ],
    );
  }
}

class _AlertaCard extends StatelessWidget {
  const _AlertaCard({required this.alerta, required this.onAbrirInscripcion});

  final PiarAlerta alerta;
  final void Function(String inscripcionId) onAbrirInscripcion;

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    final inscripcionId = alerta.entidadRelacionadaTipo == 'inscripcion'
        ? alerta.entidadRelacionadaId
        : (alerta.entidadRelacionadaTipo == 'ajuste'
              ? piar.ajusteById(alerta.entidadRelacionadaId ?? '')?.inscripcionId
              : null);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _kTipoAlertaIconos[alerta.tipo] ?? Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kTipoAlertaLabels[alerta.tipo] ?? 'Alerta',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(alerta.mensaje, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (inscripcionId != null)
                      TextButton(
                        onPressed: () => onAbrirInscripcion(inscripcionId),
                        child: const Text('Ver inscripción'),
                      ),
                    TextButton(
                      onPressed: () => piar.marcarAlertaLeida(alerta.id),
                      child: const Text('Marcar como leída'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
