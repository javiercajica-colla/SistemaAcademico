import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';
import 'piar_teacher_ajustes_view.dart';

/// "Mis estudiantes con PIAR" (Fase 5): visible para todos los docentes,
/// pero solo aparecen aquí los estudiantes activos en el módulo PIAR cuya
/// carga académica ya resolvió a este docente como responsable de al menos
/// una competencia (nunca por asignación manual, ver PiarProvider.
/// misEstudiantesPiar). Un docente nunca ve estudiantes de otras
/// asignaturas ni ningún soporte externo desde esta pantalla.
class PiarTeacherScreen extends StatefulWidget {
  const PiarTeacherScreen({super.key});

  @override
  State<PiarTeacherScreen> createState() => _PiarTeacherScreenState();
}

class _PiarTeacherScreenState extends State<PiarTeacherScreen> {
  String? _inscripcionSeleccionadaId;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) {
      return const Center(child: Text('No se encontró el perfil de docente.'));
    }

    if (_inscripcionSeleccionadaId != null) {
      return PiarTeacherAjustesView(
        inscripcionId: _inscripcionSeleccionadaId!,
        teacher: teacher,
        onVolver: () => setState(() => _inscripcionSeleccionadaId = null),
      );
    }

    return _PiarTeacherListView(
      teacher: teacher,
      onSeleccionar: (id) => setState(() => _inscripcionSeleccionadaId = id),
    );
  }
}

class _PiarTeacherListView extends StatelessWidget {
  const _PiarTeacherListView({required this.teacher, required this.onSeleccionar});

  final Teacher teacher;
  final void Function(String inscripcionId) onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    final inscripciones = piar.misEstudiantesPiar(teacher.id)
      ..sort((a, b) {
        final sa = _studentName(academic, a.studentId);
        final sb = _studentName(academic, b.studentId);
        return sa.compareTo(sb);
      });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis estudiantes con PIAR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estudiantes de tu carga académica con Plan Individual de Ajustes '
            'Razonables activo. Aquí defines los ajustes para tus asignaturas '
            '— no verás informes ni diagnósticos, solo barreras y apoyos.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (inscripciones.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Por ahora ningún estudiante de tu carga académica tiene un '
                  'PIAR activo.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: inscripciones.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final insc = inscripciones[i];
                  final course = academic.courseById(insc.courseId);
                  final pendientes = piar
                      .ajustesForDocente(insc.id, teacher.id)
                      .where((a) => a.requiereAjuste == null)
                      .length;
                  final total = piar.ajustesForDocente(insc.id, teacher.id).length;
                  return AppCard(
                    child: InkWell(
                      onTap: () => onSeleccionar(insc.id),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.teacher.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.accessibility_new_rounded,
                              color: AppColors.teacher,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _studentName(academic, insc.studentId),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
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
                          if (pendientes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$pendientes pendiente${pendientes == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$total al día',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _studentName(AcademicProvider academic, String studentId) {
    try {
      return academic.students.firstWhere((s) => s.id == studentId).fullName;
    } catch (_) {
      return 'Estudiante';
    }
  }
}
