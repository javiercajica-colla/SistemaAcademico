import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final student = academic.studentByUserId(auth.currentUser!.id);
    if (student == null) return const Center(child: Text('Perfil no encontrado'));

    final allAttendance = academic.attendanceForStudent(student.id);
    final fmt = DateFormat('dd/MM/yyyy');
    final present = allAttendance.where((a) => a.status == AttendanceStatus.present).length;
    final absent = allAttendance.where((a) => a.status == AttendanceStatus.absent).length;
    final late = allAttendance.where((a) => a.status == AttendanceStatus.late).length;
    final excused = allAttendance.where((a) => a.status == AttendanceStatus.excused).length;
    final pct = allAttendance.isNotEmpty ? (present / allAttendance.length * 100) : 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Mi Asistencia', subtitle: 'Historial de asistencia por asignatura'),
          const SizedBox(height: 20),
          _buildSummaryCards(allAttendance.length, present, absent, late, excused, pct),
          const SizedBox(height: 20),
          AppCard(
            title: 'Historial de Asistencia',
            child: allAttendance.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No hay registros de asistencia')))
                : Column(
                    children: allAttendance.reversed.take(20).map((a) {
                      final subject = academic.subjectById(a.subjectId);
                      final Color c;
                      final IconData ic;
                      final String label;
                      switch (a.status) {
                        case AttendanceStatus.present: c = AppColors.secondary; ic = Icons.check_circle_rounded; label = 'Presente';
                        case AttendanceStatus.absent: c = AppColors.error; ic = Icons.cancel_rounded; label = 'Ausente';
                        case AttendanceStatus.late: c = AppColors.warning; ic = Icons.schedule_rounded; label = 'Tardanza';
                        case AttendanceStatus.excused: c = AppColors.primary; ic = Icons.medical_services_rounded; label = 'Excusado';
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(ic, color: c, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(subject?.name ?? 'Asignatura', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                Text(fmt.format(a.date), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
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

  Widget _buildSummaryCards(int total, int present, int absent, int late, int excused, double pct) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pct >= 80 ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pct >= 80 ? AppColors.secondary.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(pct >= 80 ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: pct >= 80 ? AppColors.secondary : AppColors.warning, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${pct.toStringAsFixed(1)}% de asistencia',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: pct >= 80 ? AppColors.secondary : AppColors.warning)),
                  Text(pct >= 80 ? 'Tu asistencia está en buen nivel' : 'Debes mejorar tu asistencia',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 90,
          ),
          children: [
            StatCard(title: 'Total Clases', value: '$total', icon: Icons.class_rounded, color: AppColors.primary),
            StatCard(title: 'Presentes', value: '$present', icon: Icons.check_circle_rounded, color: AppColors.secondary),
            StatCard(title: 'Ausentes', value: '$absent', icon: Icons.cancel_rounded, color: AppColors.error),
            StatCard(title: 'Tardanzas', value: '$late', icon: Icons.schedule_rounded, color: AppColors.warning),
          ],
        ),
      ],
    );
  }
}
