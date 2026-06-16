import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    return Row(
      children: [
        SizedBox(
          width: 260,
          child: Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nuevo Curso'),
                      onPressed: () => _showCourseDialog(context),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: academic.courses.length,
                    itemBuilder: (_, i) {
                      final c = academic.courses[i];
                      final count = academic.studentsInCourse(c.id).length;
                      final isSelected = c.id == _selectedCourse;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCourse = c.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.coordinator.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      c.grade,
                                      style: const TextStyle(
                                        color: AppColors.coordinator,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '$count estudiantes',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
          child: _selectedCourse == null
              ? _buildEmptyState()
              : _buildCourseDetail(context, academic),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'Selecciona un curso',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDetail(BuildContext context, AcademicProvider academic) {
    final course = academic.courseById(_selectedCourse!);
    if (course == null) return _buildEmptyState();
    final students = academic.studentsInCourse(course.id);
    final subjectAssignments = academic.assignments
        .where((a) => a.courseId == course.id)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'Grado ${course.grade}° • Sección ${course.section}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('Matricular Estudiante'),
                        onPressed: () => _showEnrollDialog(context, academic),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Estudiantes'),
                    Tab(text: 'Asignaturas'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStudentsList(students, academic),
                _buildSubjectsList(subjectAssignments, academic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(List<dynamic> students, AcademicProvider academic) {
    if (students.isEmpty) {
      return const Center(child: Text('No hay estudiantes matriculados'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: students.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = students[i];
        final avg = academic.calculateOverallAverage(s.id, 'ap1');
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.student.withValues(alpha: 0.1),
            child: Text(
              s.firstName.substring(0, 1),
              style: const TextStyle(
                color: AppColors.student,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            s.fullName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('Doc: ${s.documentId}'),
          trailing: avg > 0
              ? GradeChip(grade: avg)
              : const Text(
                  'Sin calificaciones',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
        );
      },
    );
  }

  Widget _buildSubjectsList(
    List subjectAssignments,
    AcademicProvider academic,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: subjectAssignments.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final sa = subjectAssignments[i];
        final subject = academic.subjectById(sa.subjectId);
        final teacher = academic.teacherById(sa.teacherId);
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          title: Text(
            subject?.name ?? 'Asignatura',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(subject?.area ?? ''),
          trailing: teacher != null
              ? Chip(
                  label: Text(
                    teacher.fullName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppColors.teacher.withValues(alpha: 0.08),
                )
              : const Text(
                  'Sin docente',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
        );
      },
    );
  }

  void _showCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Curso / Grupo'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Grado'),
                items: ['6', '7', '8', '9', '10', '11']
                    .map(
                      (g) =>
                          DropdownMenuItem(value: g, child: Text('Grado $g°')),
                    )
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sección'),
                items: ['A', 'B', 'C']
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text('Sección $s')),
                    )
                    .toList(),
                onChanged: (_) {},
              ),
            ],
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEnrollDialog(BuildContext context, AcademicProvider academic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Matricular Estudiante'),
        content: SizedBox(
          width: 360,
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Seleccionar estudiante',
            ),
            items: academic.students
                .where(
                  (s) => s.courseId == null || s.courseId != _selectedCourse,
                )
                .map(
                  (s) => DropdownMenuItem(value: s.id, child: Text(s.fullName)),
                )
                .toList(),
            onChanged: (_) {},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Matricular'),
          ),
        ],
      ),
    );
  }
}
