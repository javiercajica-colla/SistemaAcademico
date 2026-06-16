import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedCourse;
  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  final Map<String, AttendanceStatus> _statuses = {};

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);
    if (teacher == null) {
      return const Center(child: Text('Perfil no encontrado'));
    }

    final myAssignments = academic.assignmentsForTeacher(teacher.id);
    final myCourseIds = myAssignments.map((a) => a.courseId).toSet();
    final myCourses = academic.courses
        .where((c) => myCourseIds.contains(c.id))
        .toList();
    final subjectIds = _selectedCourse != null
        ? myAssignments
              .where((a) => a.courseId == _selectedCourse)
              .map((a) => a.subjectId)
              .toList()
        : <String>[];
    final students = _selectedCourse != null
        ? academic.studentsInCourse(_selectedCourse!)
        : <Student>[];

    final fmt = DateFormat('dd/MM/yyyy');
    final present = _statuses.values
        .where((s) => s == AttendanceStatus.present)
        .length;
    final absent = _statuses.values
        .where((s) => s == AttendanceStatus.absent)
        .length;
    final late = _statuses.values
        .where((s) => s == AttendanceStatus.late)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Control de Asistencia',
            subtitle: 'Registra la asistencia de los estudiantes',
          ),
          const SizedBox(height: 20),
          _buildFilters(myCourses, academic, subjectIds, fmt),
          if (_selectedCourse != null && _selectedSubject != null) ...[
            const SizedBox(height: 16),
            _buildSummaryRow(students.length, present, absent, late),
            const SizedBox(height: 16),
            _buildStudentList(context, students, academic),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(
    List myCourses,
    AcademicProvider academic,
    List<String> subjectIds,
    DateFormat fmt,
  ) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCourse,
            decoration: const InputDecoration(labelText: 'Curso'),
            items: myCourses
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _selectedCourse = v;
              _selectedSubject = null;
              _statuses.clear();
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Asignatura'),
            items: subjectIds.map((sid) {
              final sub = academic.subjectById(sid);
              return DropdownMenuItem<String>(
                value: sid,
                child: Text(sub?.name ?? sid),
              );
            }).toList(),
            onChanged: _selectedCourse == null
                ? null
                : (v) => setState(() => _selectedSubject = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2026, 1),
                lastDate: DateTime(2026, 12),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha',
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(
                fmt.format(_selectedDate),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(int total, int present, int absent, int late) {
    return Row(
      children: [
        _summaryChip('Total', '$total', AppColors.primary),
        const SizedBox(width: 8),
        _summaryChip('Presentes', '$present', AppColors.secondary),
        const SizedBox(width: 8),
        _summaryChip('Ausentes', '$absent', AppColors.error),
        const SizedBox(width: 8),
        _summaryChip('Tardanzas', '$late', AppColors.warning),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.save_rounded, size: 16),
          label: const Text('Guardar Asistencia'),
          onPressed: () => _saveAttendance(context),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStudentList(
    BuildContext context,
    List<Student> students,
    AcademicProvider academic,
  ) {
    return AppCard(
      title: 'Lista de Estudiantes',
      child: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 12),
          ...students.map((s) {
            final status = _statuses[s.id] ?? AttendanceStatus.present;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _statusBgColor(status),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusColor(status).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _statusColor(
                      status,
                    ).withValues(alpha: 0.15),
                    child: Text(
                      s.firstName.substring(0, 1),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Doc: ${s.documentId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusToggle(s.id, status),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem('Presente', AppColors.secondary),
        const SizedBox(width: 12),
        _legendItem('Ausente', AppColors.error),
        const SizedBox(width: 12),
        _legendItem('Tardanza', AppColors.warning),
        const SizedBox(width: 12),
        _legendItem('Excusado', AppColors.primary),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(String studentId, AttendanceStatus current) {
    return SegmentedButton<AttendanceStatus>(
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 32),
      ),
      segments: const [
        ButtonSegment(
          value: AttendanceStatus.present,
          icon: Icon(Icons.check_rounded, size: 16),
          tooltip: 'Presente',
        ),
        ButtonSegment(
          value: AttendanceStatus.absent,
          icon: Icon(Icons.close_rounded, size: 16),
          tooltip: 'Ausente',
        ),
        ButtonSegment(
          value: AttendanceStatus.late,
          icon: Icon(Icons.schedule_rounded, size: 16),
          tooltip: 'Tardanza',
        ),
        ButtonSegment(
          value: AttendanceStatus.excused,
          icon: Icon(Icons.medical_services_rounded, size: 16),
          tooltip: 'Excusado',
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => setState(() => _statuses[studentId] = s.first),
    );
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return AppColors.secondary;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.excused:
        return AppColors.primary;
    }
  }

  Color _statusBgColor(AttendanceStatus s) {
    return _statusColor(s).withValues(alpha: 0.05);
  }

  void _saveAttendance(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    const uuid = Uuid();
    int saved = 0;
    for (final entry in _statuses.entries) {
      academic.addAttendance(
        AttendanceRecord(
          id: uuid.v4(),
          studentId: entry.key,
          subjectId: _selectedSubject!,
          periodId: academic.currentOpenPeriod?.id ?? 'ap2',
          date: _selectedDate,
          status: entry.value,
        ),
      );
      saved++;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asistencia guardada para $saved estudiantes'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}
