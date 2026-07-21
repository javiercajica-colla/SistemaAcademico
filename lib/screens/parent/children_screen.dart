import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  String? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final parent = academic.parentByUserId(auth.currentUser!.id);
    if (parent == null) {
      return const Center(child: Text('Perfil no encontrado'));
    }

    final myStudents = academic.students
        .where((s) => parent.studentIds.contains(s.id))
        .toList();
    _selectedStudent ??= myStudents.isNotEmpty ? myStudents.first.id : null;

    return Row(
      children: [
        SizedBox(
          width: 240,
          child: Container(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Mis Hijos',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: myStudents.length,
                    itemBuilder: (_, i) {
                      final s = myStudents[i];
                      final isSelected = s.id == _selectedStudent;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.parent.withValues(
                          alpha: 0.08,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.parent.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            s.firstName.substring(0, 1),
                            style: const TextStyle(
                              color: AppColors.parent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          s.fullName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          academic.courseById(s.courseId ?? '')?.name ??
                              'Sin curso',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => setState(() => _selectedStudent = s.id),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedStudent == null
              ? const Center(child: Text('Selecciona un hijo'))
              : _buildStudentDetail(context, academic, _selectedStudent!),
        ),
      ],
    );
  }

  Widget _buildStudentDetail(
    BuildContext context,
    AcademicProvider academic,
    String studentId,
  ) {
    final student = academic.students.firstWhere((s) => s.id == studentId);
    final course = academic.courseById(student.courseId ?? '');
    final attendance = academic.attendanceForStudent(studentId);
    final observations = academic.observationsForStudent(studentId);
    final absents = attendance
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final fmt = DateFormat('dd/MM/yyyy');

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.parent.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          student.firstName.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.parent,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${course?.name ?? 'Sin curso'} • Doc: ${student.documentId}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Calificaciones'),
                    Tab(text: 'Asistencia'),
                    Tab(text: 'Observaciones'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGradesTab(studentId, academic),
                _buildAttendanceTab(attendance, academic, fmt, absents),
                _buildObservationsTab(observations, academic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTab(String studentId, AcademicProvider academic) {
    final subjects = academic.subjects;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: subjects.map((s) {
          final avg = academic.calculateSubjectPeriodGrade(
            studentId,
            s.id,
            'ap1',
          );
          if (avg == 0) return const SizedBox.shrink();
          final color = avg >= 4.0
              ? AppColors.secondary
              : avg >= 3.0
              ? AppColors.warning
              : AppColors.error;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  GradeChip(grade: avg),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      avg >= 4.6
                          ? 'Superior'
                          : avg >= 4.0
                          ? 'Alto'
                          : avg >= 3.0
                          ? 'Básico'
                          : 'Bajo',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceTab(
    List<AttendanceRecord> attendance,
    AcademicProvider academic,
    DateFormat fmt,
    int absents,
  ) {
    final pct = attendance.isNotEmpty
        ? ((attendance.length - absents) / attendance.length * 100)
        : 100.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Asistencia',
                  value: '${pct.toStringAsFixed(0)}%',
                  icon: Icons.fact_check_rounded,
                  color: pct >= 80 ? AppColors.secondary : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Inasistencias',
                  value: '$absents',
                  icon: Icons.event_busy_rounded,
                  color: absents == 0 ? AppColors.secondary : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            title: 'Detalle de Asistencia',
            child: Column(
              children: attendance.reversed.map((a) {
                final sub = academic.subjectById(a.subjectId);
                final Color c;
                final String label;
                switch (a.status) {
                  case AttendanceStatus.present:
                    c = AppColors.secondary;
                    label = 'Presente';
                  case AttendanceStatus.absent:
                    c = AppColors.error;
                    label = 'Ausente';
                  case AttendanceStatus.late:
                    c = AppColors.warning;
                    label = 'Tardanza';
                  case AttendanceStatus.excused:
                    c = AppColors.primary;
                    label = 'Excusado';
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sub?.name ?? 'Asignatura',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        fmt.format(a.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: c,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsTab(
    List<Observation> observations,
    AcademicProvider academic,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: observations.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Sin observaciones registradas'),
              ),
            )
          : Column(
              children: observations.map((o) {
                final subject = o.subjectId != null
                    ? academic.subjectById(o.subjectId!)
                    : null;
                final teacher = academic.teacherById(o.teacherId);
                final Color c = o.type == ObservationType.positive
                    ? AppColors.secondary
                    : o.type == ObservationType.disciplinary
                    ? AppColors.error
                    : AppColors.warning;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(color: c, width: 4),
                        top: const BorderSide(color: AppColors.border),
                        right: const BorderSide(color: AppColors.border),
                        bottom: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                o.type == ObservationType.positive
                                    ? 'Positiva'
                                    : o.type == ObservationType.disciplinary
                                    ? 'Disciplinaria'
                                    : 'Académica',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (subject != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                subject.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              DateFormat('dd/MM/yyyy').format(o.date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          o.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          o.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (teacher != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Docente: ${teacher.fullName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
