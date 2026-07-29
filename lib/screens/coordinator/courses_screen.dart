import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
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
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) setState(() {});
      });
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
    final isSubjectsTab = _tabs.index == 1;

    return Column(
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
                      icon: Icon(
                        isSubjectsTab
                            ? Icons.book_rounded
                            : Icons.person_add_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isSubjectsTab
                            ? 'Agregar Asignatura'
                            : 'Matricular Estudiante',
                      ),
                      onPressed: () => isSubjectsTab
                          ? _showAddSubjectToGradeDialog(
                              context,
                              academic,
                              course,
                            )
                          : _showEnrollDialog(context, academic),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Estudiantes'),
                  Tab(text: 'Asignaturas'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildStudentsList(students, academic),
              _buildSubjectsList(subjectAssignments, academic),
            ],
          ),
        ),
      ],
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
    List<SubjectAssignment> subjectAssignments,
    AcademicProvider academic,
  ) {
    if (subjectAssignments.isEmpty) {
      return const Center(child: Text('Sin asignaturas asignadas aún'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: subjectAssignments.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final sa = subjectAssignments[i];
        final subject = academic.subjectById(sa.subjectId);
        final assignedTeacherId = sa.teacherId;
        final teacher = assignedTeacherId == null
            ? null
            : academic.teacherById(assignedTeacherId);
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
                  'Sin docente asignado',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
        );
      },
    );
  }

  void _showCourseDialog(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    String? selectedGrade;
    String? selectedSection;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Curso / Grupo'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedGrade,
                    decoration: const InputDecoration(labelText: 'Grado'),
                    items: ['6', '7', '8', '9', '10', '11']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text('Grado $g°'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedGrade = v;
                      errorMsg = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSection,
                    decoration: const InputDecoration(labelText: 'Sección'),
                    items: ['A', 'B', 'C']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('Sección $s'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedSection = v;
                      errorMsg = null;
                    }),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: (selectedGrade == null || selectedSection == null)
                  ? null
                  : () {
                      final grade = selectedGrade!;
                      final section = selectedSection!;
                      final exists = academic.courses.any(
                        (c) =>
                            c.grade == grade &&
                            c.section == section &&
                            c.academicYearId == academic.activeYear.id,
                      );
                      if (exists) {
                        setDialogState(
                          () => errorMsg = 'Ya existe el curso $grade°$section.',
                        );
                        return;
                      }
                      // Cerrar el diálogo ANTES de mutar el provider y
                      // diferir la mutación al siguiente microtask evita el
                      // assertion "_dependents.isEmpty" al chocar con el
                      // cierre del diálogo en el mismo frame.
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        academic.addCourse(
                          Course(
                            id: const Uuid().v4(),
                            name: '$grade° $section',
                            grade: grade,
                            section: section,
                            academicYearId: academic.activeYear.id,
                          ),
                        );
                      });
                    },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollDialog(BuildContext context, AcademicProvider academic) {
    String? selectedStudentId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Matricular Estudiante'),
          content: SizedBox(
            width: 360,
            child: DropdownButtonFormField<String>(
              initialValue: selectedStudentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Seleccionar estudiante',
              ),
              items: academic.students
                  .where(
                    (s) => s.courseId == null || s.courseId != _selectedCourse,
                  )
                  .map(
                    (s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.fullName)),
                  )
                  .toList(),
              onChanged: (v) => setDialogState(() => selectedStudentId = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedStudentId == null
                  ? null
                  : () {
                      final student = academic.studentById(
                        selectedStudentId!,
                      );
                      // Cerrar el diálogo ANTES de mutar el provider y
                      // diferir la mutación al siguiente microtask evita el
                      // assertion "_dependents.isEmpty" al chocar con el
                      // cierre del diálogo en el mismo frame.
                      Navigator.pop(ctx);
                      if (student == null) return;
                      Future.microtask(() {
                        academic.updateStudent(
                          Student(
                            id: student.id,
                            userId: student.userId,
                            firstName: student.firstName,
                            lastName: student.lastName,
                            documentId: student.documentId,
                            birthDate: student.birthDate,
                            courseId: _selectedCourse,
                            parentIds: student.parentIds,
                          ),
                        );
                      });
                    },
              child: const Text('Matricular'),
            ),
          ],
        ),
      ),
    );
  }

  // Asigna una asignatura a TODAS las secciones del mismo grado (ej. 6°A,
  // 6°B) de una sola vez, en vez de una por una desde Usuarios. El docente
  // es opcional aquí porque puede variar por sección y definirse después
  // (Usuarios → editar docente); las secciones que ya tenían esa asignatura
  // se dejan intactas para no pisar un docente ya asignado.
  void _showAddSubjectToGradeDialog(
    BuildContext context,
    AcademicProvider academic,
    Course course,
  ) {
    String? selectedSubjectId;
    String? selectedTeacherId;
    final sectionsInGrade = academic.courses
        .where(
          (c) =>
              c.grade == course.grade &&
              c.academicYearId == course.academicYearId,
        )
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Agregar Asignatura al Grado ${course.grade}°'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se agregará a las ${sectionsInGrade.length} secciones del '
                  'grado ${course.grade}° (${sectionsInGrade.map((c) => c.section).join(', ')}). '
                  'Las secciones que ya tengan esta asignatura no se modifican.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Asignatura'),
                  items: academic.subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedSubjectId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedTeacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Docente (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin asignar todavía'),
                    ),
                    ...academic.teachers.map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(
                          t.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedTeacherId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedSubjectId == null
                  ? null
                  : () {
                      final subjectId = selectedSubjectId!;
                      final teacherId = selectedTeacherId;
                      // Cerrar el diálogo ANTES de mutar el provider y
                      // diferir la mutación al siguiente microtask evita el
                      // assertion "_dependents.isEmpty" al chocar con el
                      // cierre del diálogo en el mismo frame.
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        var added = 0;
                        for (final c in sectionsInGrade) {
                          final alreadyAssigned = academic.assignments.any(
                            (a) =>
                                a.courseId == c.id && a.subjectId == subjectId,
                          );
                          if (alreadyAssigned) continue;
                          academic.addAssignment(
                            SubjectAssignment(
                              id: const Uuid().v4(),
                              teacherId: teacherId,
                              subjectId: subjectId,
                              courseId: c.id,
                              academicYearId: c.academicYearId,
                            ),
                          );
                          added++;
                        }
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added == 0
                                  ? 'Todas las secciones del grado ${course.grade}° ya tenían esa asignatura.'
                                  : 'Asignatura agregada a $added de ${sectionsInGrade.length} secciones del grado ${course.grade}°.',
                            ),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      });
                    },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
