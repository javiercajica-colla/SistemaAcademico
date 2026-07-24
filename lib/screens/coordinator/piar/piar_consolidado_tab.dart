import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/piar_models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';

const _kValoracionLabels = {
  PiarValoracion.logradoAutonomia: 'Logrado con autonomía',
  PiarValoracion.logradoConApoyo: 'Logrado con apoyo',
  PiarValoracion.enProceso: 'En proceso',
  PiarValoracion.sinAvance: 'Sin avance',
};

const _kDecisionLabels = {
  PiarDecisionAjuste.mantener: 'Mantener',
  PiarDecisionAjuste.modificar: 'Modificar',
  PiarDecisionAjuste.retirar: 'Retirar',
  PiarDecisionAjuste.escalar: 'Escalar',
};

/// Consolidado por estudiante (Fase 9): una fila por competencia con su
/// estado, el último seguimiento y el diagnóstico final — la vista que
/// coordinación usa para revisar todo antes de cerrar el año.
class PiarConsolidadoTab extends StatelessWidget {
  const PiarConsolidadoTab({super.key, required this.inscripcionId});

  final String inscripcionId;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    final ajustes = piar.ajustesFor(inscripcionId);

    if (ajustes.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no hay competencias registradas para este PIAR.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final porAsignatura = <String, List<PiarAjuste>>{};
    for (final a in ajustes) {
      porAsignatura.putIfAbsent(a.subjectId, () => []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final subjectId in porAsignatura.keys) ...[
          Text(
            academic.subjectById(subjectId)?.name ?? 'Asignatura',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.coordinator),
          ),
          const SizedBox(height: 8),
          for (final ajuste in porAsignatura[subjectId]!) ...[
            _AjusteConsolidadoCard(ajuste: ajuste),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AjusteConsolidadoCard extends StatelessWidget {
  const _AjusteConsolidadoCard({required this.ajuste});

  final PiarAjuste ajuste;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    final docente = academic.teacherById(ajuste.docenteResponsableId);
    final ultimoSeguimiento = piar.seguimientoActualPara(ajuste.id);
    final diagnostico = piar.diagnosticoFinalPara(ajuste.inscripcionId, ajuste.standardId);
    final standardName = _standardName(academic, ajuste.standardId);

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
                    Text(standardName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      'Docente: ${docente?.fullName ?? "—"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _EstadoRequerimiento(ajuste: ajuste),
            ],
          ),
          if (ultimoSeguimiento != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Último seguimiento: ${_kValoracionLabels[ultimoSeguimiento.valoracion]} · '
                'Decisión: ${_kDecisionLabels[ultimoSeguimiento.decisionAjuste]}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
          if (ajuste.requiereAjuste == true) ...[
            const SizedBox(height: 10),
            if (diagnostico != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnóstico final: ${_kValoracionLabels[diagnostico.valoracionFinal]}'
                      '${diagnostico.tuvoAjusteSignificativo ? " · Tuvo ajuste significativo" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                    if (diagnostico.observacion.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(diagnostico.observacion, style: const TextStyle(fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: Text(diagnostico == null ? 'Registrar diagnóstico final' : 'Editar diagnóstico final'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _DiagnosticoDialog(
                  ajuste: ajuste,
                  existente: diagnostico,
                  sugerido: ultimoSeguimiento?.valoracion,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _standardName(AcademicProvider academic, String standardId) {
    try {
      return academic.standards.firstWhere((s) => s.id == standardId).name;
    } catch (_) {
      return 'Competencia';
    }
  }
}

class _EstadoRequerimiento extends StatelessWidget {
  const _EstadoRequerimiento({required this.ajuste});

  final PiarAjuste ajuste;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (ajuste.requiereAjuste) {
      null => ('Pendiente', AppColors.warning),
      false => ('Sin ajuste', AppColors.textSecondary),
      true => ('Con ajuste', AppColors.coordinator),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _DiagnosticoDialog extends StatefulWidget {
  const _DiagnosticoDialog({
    required this.ajuste,
    required this.existente,
    required this.sugerido,
  });

  final PiarAjuste ajuste;
  final PiarDiagnosticoFinal? existente;
  final PiarValoracion? sugerido;

  @override
  State<_DiagnosticoDialog> createState() => _DiagnosticoDialogState();
}

class _DiagnosticoDialogState extends State<_DiagnosticoDialog> {
  PiarValoracion? _valoracion;
  late final TextEditingController _observacionCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _valoracion = widget.existente?.valoracionFinal ?? widget.sugerido;
    _observacionCtrl = TextEditingController(text: widget.existente?.observacion ?? '');
  }

  @override
  void dispose() {
    _observacionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Diagnóstico final'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valoración final de la competencia',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PiarValoracion.values.map((v) {
                return ChoiceChip(
                  label: Text(_kValoracionLabels[v]!),
                  selected: _valoracion == v,
                  onSelected: (_) => setState(() => _valoracion = v),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _observacionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observación de cierre'),
            ),
            if (widget.ajuste.esSignificativo) ...[
              const SizedBox(height: 10),
              const Text(
                'Este ajuste fue significativo (meta distinta a la del curso).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_valoracion == null || _guardando) ? null : _guardar,
          child: Text(_guardando ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final piar = context.read<PiarProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    final now = DateTime.now();

    await piar.guardarDiagnosticoFinal(
      PiarDiagnosticoFinal(
        id: widget.existente?.id ?? const Uuid().v4(),
        inscripcionId: widget.ajuste.inscripcionId,
        standardId: widget.ajuste.standardId,
        valoracionFinal: _valoracion!,
        tuvoAjusteSignificativo: widget.ajuste.esSignificativo,
        observacion: _observacionCtrl.text.trim(),
        creadoPor: widget.existente?.creadoPor ?? uid,
        creadoEn: widget.existente?.creadoEn ?? now,
        actualizadoPor: uid,
        actualizadoEn: now,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }
}
