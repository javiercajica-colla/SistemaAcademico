import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

const _kAutofillNote = 'Generado automáticamente (herramienta de pruebas)';

/// Herramienta de pruebas, solo para Administrador: genera notas aleatorias
/// (1.0-5.0) para todos los estudiantes en todas las asignaturas de su curso,
/// en el período seleccionado (o en todos). Si una asignatura todavía no
/// tiene Estándares/Competencias/Actividades para ese período, los crea
/// (4 Estándares, 2 Competencias cada uno, 1 Actividad cada una) antes de
/// registrar la nota. Sobrescribe notas existentes en esas actividades.
class GradeAutofillScreen extends StatefulWidget {
  const GradeAutofillScreen({super.key});

  @override
  State<GradeAutofillScreen> createState() => _GradeAutofillScreenState();
}

class _GradeAutofillScreenState extends State<GradeAutofillScreen> {
  static const _uuid = Uuid();
  final _random = Random();

  String? _selectedPeriodId; // null = todos los períodos
  bool _running = false;
  String _statusText = '';
  int _gradesCreated = 0;

  Future<void> _runAutofill(AcademicProvider academic) async {
    final periods = _selectedPeriodId == null
        ? academic.activePeriods
        : academic.activePeriods
              .where((p) => p.id == _selectedPeriodId)
              .toList();
    if (periods.isEmpty) return;

    setState(() {
      _running = true;
      _gradesCreated = 0;
      _statusText = 'Iniciando...';
    });

    var writes = 0;

    for (final course in academic.courses) {
      final students = academic.studentsInCourse(course.id);
      if (students.isEmpty) continue;
      final subjects = academic.subjectsForCourse(course.id);

      for (final subject in subjects) {
        var estandares = academic.estandaresForSubject(subject.id);
        if (estandares.isEmpty) {
          estandares = List.generate(4, (i) {
            final e = Estandar(
              id: _uuid.v4(),
              subjectId: subject.id,
              academicYearId: academic.activeYear.id,
              name: 'Estándar ${i + 1}',
              description: _kAutofillNote,
              order: i + 1,
              weight: 0,
            );
            academic.addEstandar(e);
            return e;
          });
        }

        for (final period in periods) {
          for (final estandar in estandares) {
            var competencias = academic.competenciasForEstandarAndPeriod(
              estandar.id,
              period.id,
            );
            if (competencias.isEmpty) {
              final cognitiva = Competencia(
                id: _uuid.v4(),
                estandarId: estandar.id,
                periodId: period.id,
                tipo: CompetenciaTipo.cognitiva,
                name: 'Competencia 1',
                description: _kAutofillNote,
                order: 1,
              );
              final actitudinal = Competencia(
                id: _uuid.v4(),
                estandarId: estandar.id,
                periodId: period.id,
                tipo: CompetenciaTipo.actitudinal,
                name: 'Competencia 2',
                description: _kAutofillNote,
                order: 2,
              );
              academic.addCompetencia(cognitiva);
              academic.addCompetencia(actitudinal);
              competencias = [cognitiva, actitudinal];
            }

            for (final competencia in competencias) {
              var actividades = academic.actividadesForCompetencia(
                competencia.id,
              );
              if (actividades.isEmpty) {
                final actividad = Actividad(
                  id: _uuid.v4(),
                  competenciaId: competencia.id,
                  name: 'Actividad 1',
                  description: _kAutofillNote,
                  order: 1,
                );
                academic.addActividad(actividad);
                actividades = [actividad];
              }

              for (final actividad in actividades) {
                for (final student in students) {
                  final value = double.parse(
                    (1 + _random.nextDouble() * 4).toStringAsFixed(1),
                  );
                  academic.addGrade(
                    Grade(
                      id: _uuid.v4(),
                      studentId: student.id,
                      subjectId: subject.id,
                      periodId: period.id,
                      estandarId: estandar.id,
                      competenciaId: competencia.id,
                      actividadId: actividad.id,
                      value: value,
                      note: _kAutofillNote,
                      registeredAt: DateTime.now(),
                    ),
                  );
                  writes++;
                  if (writes % 40 == 0) {
                    if (!mounted) return;
                    setState(() {
                      _gradesCreated = writes;
                      _statusText =
                          '${course.name} · ${subject.name} · ${period.name}';
                    });
                    await Future.delayed(const Duration(milliseconds: 15));
                  }
                }
              }
            }
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _gradesCreated = writes;
      _statusText = 'Completado';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Listo: $writes notas generadas.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final role = auth.currentUser?.role;

    if (role != UserRole.admin) {
      return const Center(
        child: Text('Acceso restringido a Administradores.'),
      );
    }

    final periods = academic.activePeriods;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relleno automático de notas (Pruebas)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Text(
              'Genera notas aleatorias (1.0 a 5.0) para todos los estudiantes, '
              'en todas las asignaturas de su curso, para el período '
              'seleccionado. Si una asignatura no tiene Estándares/'
              'Competencias/Actividades configurados, se crean automáticamente '
              '(4 Estándares, 2 Competencias cada uno, 1 Actividad cada una). '
              'Sobrescribe notas existentes en esas actividades. Usar solo con '
              'datos de prueba.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Período a rellenar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedPeriodId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos los períodos'),
                    ),
                    ...periods.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    ),
                  ],
                  onChanged: _running
                      ? null
                      : (v) => setState(() => _selectedPeriodId = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high_rounded),
                  label: Text(
                    _running
                        ? 'Generando notas...'
                        : 'Rellenar notas automáticamente',
                  ),
                  onPressed: _running ? null : () => _runAutofill(academic),
                ),
                if (_running) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    '$_gradesCreated notas generadas · $_statusText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
