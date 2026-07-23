import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';

/// Buscador de estudiantes matriculados en el año lectivo seleccionado.
/// Al elegir uno se crea la inscripción PIAR en borrador y se abre su
/// detalle. Si el estudiante ya tiene una inscripción activa este año, se
/// avisa en vez de crear una duplicada.
class PiarInscribirDialog extends StatefulWidget {
  const PiarInscribirDialog({
    super.key,
    required this.academicYearId,
    required this.onInscrita,
  });

  final String academicYearId;
  final void Function(String inscripcionId) onInscrita;

  @override
  State<PiarInscribirDialog> createState() => _PiarInscribirDialogState();
}

class _PiarInscribirDialogState extends State<PiarInscribirDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();

    final matriculados = academic.students.where((s) {
      if (s.courseId == null) return false;
      final course = academic.courseById(s.courseId!);
      return course?.academicYearId == widget.academicYearId;
    }).toList();

    final filtrados = _query.trim().isEmpty
        ? matriculados
        : matriculados
              .where(
                (s) =>
                    s.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                    s.documentId.contains(_query),
              )
              .toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Inscribir estudiante al PIAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Solo aparecen estudiantes matriculados en el año lectivo seleccionado.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre o documento',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: filtrados.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin resultados.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (_, i) {
                          final s = filtrados[i];
                          final course = academic.courseById(s.courseId!);
                          final yaActiva = piar.inscripcionActivaDe(
                            s.id,
                            widget.academicYearId,
                          );
                          return ListTile(
                            enabled: !_guardando,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.coordinator
                                  .withValues(alpha: 0.1),
                              child: Text(
                                s.firstName.substring(0, 1),
                                style: const TextStyle(
                                  color: AppColors.coordinator,
                                ),
                              ),
                            ),
                            title: Text(s.fullName),
                            subtitle: Text(
                              '${course?.name ?? "Sin curso"} · ${s.documentId}',
                            ),
                            trailing: yaActiva != null
                                ? const Text(
                                    'Ya inscrito',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  )
                                : null,
                            onTap: () => _inscribir(context, academic, piar, s),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _inscribir(
    BuildContext context,
    AcademicProvider academic,
    PiarProvider piar,
    Student student,
  ) async {
    final yaActiva = piar.inscripcionActivaDe(student.id, widget.academicYearId);
    if (yaActiva != null) {
      setState(
        () => _error =
            '${student.fullName} ya tiene una inscripción PIAR activa este año. Ábrala desde el listado.',
      );
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final coordinadorUid = context.read<AuthProvider>().currentUser!.id;
    final padresAutorizadosIds = student.parentIds
        .map((pid) => _parentUidById(academic, pid))
        .whereType<String>()
        .toList();

    final (resultado, inscripcion) = await piar.crearInscripcion(
      studentId: student.id,
      academicYearId: widget.academicYearId,
      courseId: student.courseId!,
      coordinadorUid: coordinadorUid,
      padresAutorizadosIds: padresAutorizadosIds,
    );

    if (!context.mounted) return;

    if (resultado == PiarAccionResultado.yaExisteInscripcionActiva ||
        inscripcion == null) {
      setState(() {
        _guardando = false;
        _error =
            '${student.fullName} ya tiene una inscripción PIAR activa este año.';
      });
      return;
    }

    Navigator.pop(context);
    widget.onInscrita(inscripcion.id);
  }

  String? _parentUidById(AcademicProvider academic, String parentId) {
    try {
      return academic.parents.firstWhere((p) => p.id == parentId).userId;
    } catch (_) {
      return null;
    }
  }
}
