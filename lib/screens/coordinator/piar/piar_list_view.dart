import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../models/piar_models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';
import 'piar_inscribir_dialog.dart';

enum _FiltroCompletitud { todos, completos, incompletos }

/// Listado de inscripciones PIAR: filtros por año lectivo, grado, estado y
/// nivel de completitud, con las columnas que necesita coordinación para
/// ver de un vistazo qué estudiantes tienen el PIAR incompleto.
class PiarListView extends StatefulWidget {
  const PiarListView({super.key, required this.onAbrirDetalle});

  final void Function(String inscripcionId) onAbrirDetalle;

  @override
  State<PiarListView> createState() => _PiarListViewState();
}

class _PiarListViewState extends State<PiarListView> {
  String? _academicYearId;
  String? _grade;
  PiarEstadoInscripcion? _estado;
  _FiltroCompletitud _completitud = _FiltroCompletitud.todos;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    _academicYearId ??= academic.activeYear.id;

    final grados = academic.courses.map((c) => c.grade).toSet().toList()
      ..sort();

    var inscripciones = piar.inscripciones
        .where((i) => i.academicYearId == _academicYearId)
        .toList();
    if (_grade != null) {
      inscripciones = inscripciones
          .where((i) => academic.courseById(i.courseId)?.grade == _grade)
          .toList();
    }
    if (_estado != null) {
      inscripciones = inscripciones.where((i) => i.estado == _estado).toList();
    }
    if (_completitud != _FiltroCompletitud.todos) {
      inscripciones = inscripciones.where((i) {
        final ajustes = piar.ajustesFor(i.id);
        final definidos = ajustes
            .where((a) => a.estado != PiarEstadoAjuste.borrador)
            .length;
        final completo = ajustes.isNotEmpty && definidos == ajustes.length;
        return _completitud == _FiltroCompletitud.completos
            ? completo
            : !completo;
      }).toList();
    }
    inscripciones.sort(
      (a, b) => b.fechaInscripcion.compareTo(a.fechaInscripcion),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          color: AppColors.surface,
          child: Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'PIAR — Plan Individual de Ajustes Razonables',
                  subtitle:
                      'Inscripciones, soportes y perfiles de apoyo por estudiante.',
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Inscribir estudiante'),
                onPressed: () => _abrirInscribir(context, academic, piar),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _academicYearId,
                  decoration: const InputDecoration(labelText: 'Año lectivo'),
                  items: academic.years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y.id,
                          child: Text('${y.year}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _academicYearId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _grade,
                  decoration: const InputDecoration(labelText: 'Grado'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...grados.map(
                      (g) => DropdownMenuItem(value: g, child: Text(g)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _grade = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PiarEstadoInscripcion?>(
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...PiarEstadoInscripcion.values.map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_estadoLabel(e)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _estado = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<_FiltroCompletitud>(
                  initialValue: _completitud,
                  decoration: const InputDecoration(labelText: 'Completitud'),
                  items: const [
                    DropdownMenuItem(
                      value: _FiltroCompletitud.todos,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem(
                      value: _FiltroCompletitud.completos,
                      child: Text('PIAR completo'),
                    ),
                    DropdownMenuItem(
                      value: _FiltroCompletitud.incompletos,
                      child: Text('PIAR incompleto'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _completitud = v ?? _FiltroCompletitud.todos),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: inscripciones.isEmpty
              ? const Center(
                  child: Text(
                    'No hay inscripciones PIAR con estos filtros.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: inscripciones.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InscripcionRow(
                      inscripcion: inscripciones[i],
                      onTap: () => widget.onAbrirDetalle(inscripciones[i].id),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _abrirInscribir(
    BuildContext context,
    AcademicProvider academic,
    PiarProvider piar,
  ) {
    showDialog(
      context: context,
      builder: (_) => PiarInscribirDialog(
        academicYearId: _academicYearId ?? academic.activeYear.id,
        onInscrita: widget.onAbrirDetalle,
      ),
    );
  }

  static String _estadoLabel(PiarEstadoInscripcion e) => switch (e) {
    PiarEstadoInscripcion.borrador => 'Borrador',
    PiarEstadoInscripcion.activo => 'Activo',
    PiarEstadoInscripcion.cerrado => 'Cerrado',
  };
}

class _InscripcionRow extends StatelessWidget {
  const _InscripcionRow({required this.inscripcion, required this.onTap});

  final PiarInscripcion inscripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();

    final student = _studentById(academic, inscripcion.studentId);
    final course = academic.courseById(inscripcion.courseId);
    final ajustes = piar.ajustesFor(inscripcion.id);
    final definidos = ajustes
        .where((a) => a.estado != PiarEstadoAjuste.borrador)
        .length;
    final alertas = piar.alertasAbiertasFor(inscripcion.id);
    final acta = piar.actaFor(inscripcion.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.coordinator.withValues(alpha: 0.1),
                child: Text(
                  (student?.firstName.isNotEmpty ?? false)
                      ? student!.firstName.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: AppColors.coordinator,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.fullName ?? 'Estudiante no encontrado',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      course?.name ?? '—',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: _EstadoChip(estado: inscripcion.estado),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  ajustes.isEmpty ? '—' : '$definidos / ${ajustes.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: alertas > 0
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$alertas',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          '0',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Icon(
                    acta?.firmadaCompleta == true
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: acta?.firmadaCompleta == true
                        ? AppColors.secondary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
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

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final PiarEstadoInscripcion estado;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      PiarEstadoInscripcion.borrador => ('Borrador', AppColors.warning),
      PiarEstadoInscripcion.activo => ('Activo', AppColors.secondary),
      PiarEstadoInscripcion.cerrado => ('Cerrado', AppColors.textSecondary),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
