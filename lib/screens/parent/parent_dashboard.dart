import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final parent = academic.parentByUserId(auth.currentUser!.id);
    if (parent == null) return const Center(child: Text('Perfil de padre no encontrado'));

    final myStudents = academic.students.where((s) => parent.studentIds.contains(s.id)).toList();
    final notifications = academic.notificationsForUser(auth.currentUser!.id);
    final unread = notifications.where((n) => !n.isRead).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(parent.fullName, myStudents.length, unread),
          const SizedBox(height: 20),
          if (myStudents.isEmpty)
            const AppCard(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No tienes hijos registrados'))))
          else ...[
            ...myStudents.map((s) => _buildStudentCard(context, s, academic)),
            const SizedBox(height: 16),
            _buildNotifications(context, notifications.take(4).toList(), academic),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcome(String name, int children, int unread) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido, ${name.split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$children hijo(s) registrado(s) • Año 2026', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text('$unread nuevas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Student student, AcademicProvider academic) {
    final course = academic.courseById(student.courseId ?? '');
    final avg = academic.calculateOverallAverage(student.id, 'ap1');
    final attendance = academic.attendanceForStudent(student.id);
    final absents = attendance.where((a) => a.status == AttendanceStatus.absent).length;
    final attPct = attendance.isNotEmpty ? ((attendance.length - absents) / attendance.length * 100) : 100.0;
    final obs = academic.observationsForStudent(student.id);
    final avgColor = avg >= 4.0 ? AppColors.secondary : avg >= 3.0 ? AppColors.warning : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.parent.withValues(alpha: 0.15),
                  child: Text(student.firstName.substring(0, 1), style: const TextStyle(color: AppColors.parent, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(course?.name ?? 'Sin curso', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: avgColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Text(avg > 0 ? avg.toStringAsFixed(1) : '-', style: TextStyle(color: avgColor, fontSize: 22, fontWeight: FontWeight.w800)),
                      const Text('Promedio', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _infoBox('Asistencia', '${attPct.toStringAsFixed(0)}%', attPct >= 80 ? AppColors.secondary : AppColors.warning, Icons.fact_check_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _infoBox('Inasistencias', '$absents', absents == 0 ? AppColors.secondary : AppColors.error, Icons.event_busy_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _infoBox('Observaciones', '${obs.length}', obs.isEmpty ? AppColors.secondary : AppColors.warning, Icons.edit_note_rounded)),
              ],
            ),
            const SizedBox(height: 14),
            _buildSubjectMiniChart(student.id, academic),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSubjectMiniChart(String studentId, AcademicProvider academic) {
    final subjects = academic.subjects.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rendimiento por Asignatura', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...subjects.map((s) {
          final avg = academic.calculateSubjectPeriodGrade(studentId, s.id, 'ap1');
          if (avg == 0) return const SizedBox.shrink();
          final color = avg >= 4.0 ? AppColors.secondary : avg >= 3.0 ? AppColors.warning : AppColors.error;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text(s.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Expanded(child: LinearProgressIndicator(value: avg / 5, color: color, backgroundColor: AppColors.border, borderRadius: BorderRadius.circular(4), minHeight: 6)),
                const SizedBox(width: 8),
                SizedBox(width: 28, child: Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context, List<AppNotification> notifs, AcademicProvider academic) {
    return AppCard(
      title: 'Notificaciones Recientes',
      child: notifs.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin notificaciones')))
          : Column(
              children: notifs.map((n) {
                final Color c;
                final IconData ic;
                switch (n.type) {
                  case NotificationType.grade: c = AppColors.primary; ic = Icons.grade_rounded;
                  case NotificationType.attendance: c = AppColors.warning; ic = Icons.event_busy_rounded;
                  case NotificationType.observation: c = AppColors.purple; ic = Icons.edit_note_rounded;
                  case NotificationType.report: c = AppColors.secondary; ic = Icons.summarize_rounded;
                  default: c = AppColors.info; ic = Icons.notifications_rounded;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => academic.markNotificationRead(n.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.surfaceVariant : c.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: n.isRead ? AppColors.border : c.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 32, height: 32, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(ic, color: c, size: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 13))),
                                if (!n.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                              ]),
                              const SizedBox(height: 2),
                              Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
