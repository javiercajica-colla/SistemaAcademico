import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class ObservationsScreen extends StatefulWidget {
  const ObservationsScreen({super.key});

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen> {
  String _filter = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);
    if (teacher == null) return const Center(child: Text('Perfil no encontrado'));

    final allObs = academic.observations.where((o) => o.teacherId == teacher.id).toList();
    final filtered = allObs.where((o) {
      if (_filter != 'all' && o.type.name != _filter) return false;
      if (_search.isNotEmpty) {
        final student = academic.students.firstWhere((s) => s.id == o.studentId, orElse: () => academic.students.first);
        if (!student.fullName.toLowerCase().contains(_search) && !o.title.toLowerCase().contains(_search)) return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Observaciones',
            subtitle: 'Registra observaciones académicas y disciplinarias',
            action: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva Observación'),
              onPressed: () => _showObsDialog(context, academic, teacher.id),
            ),
          ),
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmpty()
          else
            ...filtered.map((o) => _buildObsCard(o, academic)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: const InputDecoration(hintText: 'Buscar por estudiante o título...', prefixIcon: Icon(Icons.search_rounded, size: 18), isDense: true),
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('Todas')),
            ButtonSegment(value: 'positive', icon: Icon(Icons.thumb_up_rounded, size: 14), label: Text('Positiva')),
            ButtonSegment(value: 'academic', icon: Icon(Icons.book_rounded, size: 14), label: Text('Académica')),
            ButtonSegment(value: 'disciplinary', icon: Icon(Icons.warning_rounded, size: 14), label: Text('Disciplinaria')),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('No hay observaciones registradas', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildObsCard(Observation obs, AcademicProvider academic) {
    final student = academic.students.firstWhere((s) => s.id == obs.studentId, orElse: () => academic.students.first);
    final subject = obs.subjectId != null ? academic.subjectById(obs.subjectId!) : null;
    final fmt = DateFormat('dd/MM/yyyy');

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (obs.type) {
      case ObservationType.positive:
        typeColor = AppColors.secondary; typeIcon = Icons.thumb_up_rounded; typeLabel = 'Positiva'; break;
      case ObservationType.academic:
        typeColor = AppColors.warning; typeIcon = Icons.book_rounded; typeLabel = 'Académica'; break;
      case ObservationType.disciplinary:
        typeColor = AppColors.error; typeIcon = Icons.warning_rounded; typeLabel = 'Disciplinaria'; break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: typeColor, width: 4), top: const BorderSide(color: AppColors.border), right: const BorderSide(color: AppColors.border), bottom: const BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(typeIcon, size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(typeLabel, style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 8),
                if (subject != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text(subject.name, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ),
                const Spacer(),
                Text(fmt.format(obs.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.student.withValues(alpha: 0.1),
                  child: Text(student.firstName.substring(0, 1), style: const TextStyle(color: AppColors.student, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    student.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(obs.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(obs.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }

  void _showObsDialog(BuildContext context, AcademicProvider academic, String teacherId) {
    String? selectedStudent;
    String? selectedSubject;
    ObservationType selectedType = ObservationType.academic;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nueva Observación'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Estudiante'),
                  items: academic.students.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.fullName))).toList(),
                  onChanged: (v) => setS(() => selectedStudent = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Asignatura (opcional)'),
                  items: [const DropdownMenuItem<String>(value: null, child: Text('General')), ...academic.subjects.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name)))],
                  onChanged: (v) => setS(() => selectedSubject = v),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ObservationType>(
                  segments: const [
                    ButtonSegment(value: ObservationType.positive, label: Text('Positiva')),
                    ButtonSegment(value: ObservationType.academic, label: Text('Académica')),
                    ButtonSegment(value: ObservationType.disciplinary, label: Text('Disciplinaria')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) => setS(() => selectedType = s.first),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción detallada')),
              ],
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (selectedStudent != null && titleCtrl.text.isNotEmpty && descCtrl.text.isNotEmpty) {
                  academic.addObservation(Observation(
                    id: const Uuid().v4(), studentId: selectedStudent!, teacherId: teacherId,
                    subjectId: selectedSubject, type: selectedType, title: titleCtrl.text,
                    description: descCtrl.text, date: DateTime.now(),
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Observación registrada'), backgroundColor: AppColors.secondary),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
