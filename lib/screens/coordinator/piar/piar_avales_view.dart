import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../models/piar_models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';

const _kTipoAjusteLabels = {
  PiarTipoAjuste.acceso: 'De acceso',
  PiarTipoAjuste.metodologico: 'Metodológico',
  PiarTipoAjuste.evaluativo: 'Evaluativo',
  PiarTipoAjuste.significativo: 'Significativo',
};

/// Bandeja de avales (Fase 6): cola única de ajustes significativos
/// enviados por los docentes, a la espera de que coordinación/directivo
/// los avale o los devuelva con un motivo. Solo llegan aquí ajustes con
/// `tiposAjuste` que incluye `significativo` — los demás pasan directo a
/// `enviado` sin necesitar aval (ver PiarProvider.activarInscripcion... en
/// realidad la regla vive en la pantalla del docente, Fase 5).
class PiarAvalesView extends StatelessWidget {
  const PiarAvalesView({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    final pendientes = piar.ajustesPendientesDeAval;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          color: AppColors.surface,
          child: const SectionHeader(
            title: 'Bandeja de avales',
            subtitle:
                'Ajustes significativos enviados por los docentes, a la espera '
                'de aval de coordinación.',
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: pendientes.isEmpty
              ? const Center(
                  child: Text(
                    'No hay ajustes pendientes de aval.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: pendientes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _AvalCard(ajuste: pendientes[i], academic: academic),
                ),
        ),
      ],
    );
  }
}

class _AvalCard extends StatefulWidget {
  const _AvalCard({required this.ajuste, required this.academic});

  final PiarAjuste ajuste;
  final AcademicProvider academic;

  @override
  State<_AvalCard> createState() => _AvalCardState();
}

class _AvalCardState extends State<_AvalCard> {
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    final a = widget.ajuste;
    final inscripcion = piar.inscripcionById(a.inscripcionId);
    final student = inscripcion == null
        ? null
        : _studentById(widget.academic, inscripcion.studentId);
    final course = inscripcion == null
        ? null
        : widget.academic.courseById(inscripcion.courseId);
    final subject = widget.academic.subjectById(a.subjectId);
    final teacher = widget.academic.teacherById(a.docenteResponsableId);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.fullName ?? 'Estudiante no encontrado',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${course?.name ?? "—"} · ${subject?.name ?? "—"} · '
                      'Docente: ${teacher?.fullName ?? "—"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                children: a.tiposAjuste
                    .map(
                      (t) => Chip(
                        label: Text(
                          _kTipoAjusteLabels[t]!,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: AppColors.coordinator.withValues(
                          alpha: 0.08,
                        ),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Competencia original', a.competenciaTextoOriginal),
          _row('Descripción del ajuste', a.descripcionAjuste),
          _row('Meta propuesta', a.metaMinima),
          if (a.justificacionSignificativo != null &&
              a.justificacionSignificativo!.trim().isNotEmpty)
            _row('Justificación', a.justificacionSignificativo!),
          _row('Evidencia esperada', a.evidenciaEsperada),
          if (a.apoyosAUtilizarIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: a.apoyosAUtilizarIds
                  .map((id) => piar.apoyoById(id)?.nombre)
                  .whereType<String>()
                  .map(
                    (nombre) => Chip(
                      label: Text(nombre, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.teacher.withValues(alpha: 0.08),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Devolver'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: _procesando ? null : () => _devolver(context, teacher),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Avalar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                onPressed: _procesando ? null : () => _avalar(context, teacher),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _avalar(BuildContext context, Teacher? teacher) async {
    if (teacher == null) return;
    setState(() => _procesando = true);
    final piar = context.read<PiarProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    await piar.avalarAjuste(widget.ajuste.id, uid, docenteUid: teacher.userId);
    if (!context.mounted) return;
    setState(() => _procesando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajuste avalado.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _devolver(BuildContext context, Teacher? teacher) async {
    if (teacher == null) return;
    final motivo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _MotivoDevolucionDialog(),
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    if (!context.mounted) return;

    setState(() => _procesando = true);
    final piar = context.read<PiarProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    await piar.devolverAjuste(
      widget.ajuste.id,
      uid,
      motivo.trim(),
      docenteUid: teacher.userId,
    );
    if (!context.mounted) return;
    setState(() => _procesando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajuste devuelto al docente.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Student? _studentById(AcademicProvider academic, String id) {
    try {
      return academic.students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

class _MotivoDevolucionDialog extends StatefulWidget {
  @override
  State<_MotivoDevolucionDialog> createState() =>
      _MotivoDevolucionDialogState();
}

class _MotivoDevolucionDialogState extends State<_MotivoDevolucionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Devolver ajuste al docente'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '¿Qué debe corregir o completar el docente?',
            helperText: 'El docente verá este mensaje al reabrir el ajuste.',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _ctrl.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Devolver'),
        ),
      ],
    );
  }
}
