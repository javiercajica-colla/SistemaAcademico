import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class GradesConfigScreen extends StatefulWidget {
  const GradesConfigScreen({super.key});

  @override
  State<GradesConfigScreen> createState() => _GradesConfigScreenState();
}

class _GradesConfigScreenState extends State<GradesConfigScreen> {
  String? _selectedSubject;
  String? _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Configuración de Evaluación',
            subtitle: 'Define los porcentajes de evaluación por asignatura y período',
          ),
          const SizedBox(height: 20),
          _buildFilters(academic),
          const SizedBox(height: 20),
          _buildConfigGrid(academic),
          const SizedBox(height: 24),
          _buildScaleConfig(),
        ],
      ),
    );
  }

  Widget _buildFilters(AcademicProvider academic) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedPeriod,
            decoration: const InputDecoration(labelText: 'Período Académico'),
            items: academic.activePeriods.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) => setState(() => _selectedPeriod = v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Asignatura'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas las asignaturas')),
              ...academic.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
            ],
            onChanged: (v) => setState(() => _selectedSubject = v),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigGrid(AcademicProvider academic) {
    final subjects = _selectedSubject != null
        ? academic.subjects.where((s) => s.id == _selectedSubject).toList()
        : academic.subjects;
    final periodId = _selectedPeriod ?? academic.activePeriods.first.id;

    return AppCard(
      title: 'Ponderación por Asignatura',
      titleAction: TextButton.icon(
        icon: const Icon(Icons.save_rounded, size: 16),
        label: const Text('Guardar cambios'),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada'), backgroundColor: AppColors.secondary),
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ...subjects.map((s) {
            final config = academic.evalConfigFor(s.id, periodId);
            final sw = config?.standardsWeight ?? 70;
            final fw = config?.finalExamWeight ?? 30;
            return _buildSubjectRow(s.name, sw, fw);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Asignatura', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Estándares (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Evaluación Final (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String name, double sw, double fw) {
    final total = sw + fw;
    final ok = total == 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 2,
            child: _SliderInput(value: sw, color: AppColors.primary),
          ),
          Expanded(
            flex: 2,
            child: _SliderInput(value: fw, color: AppColors.secondary),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ok ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${total.toStringAsFixed(0)}%',
                style: TextStyle(color: ok ? AppColors.secondary : AppColors.error, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleConfig() {
    return AppCard(
      title: 'Escala de Calificación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Define la escala de calificación institucional', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ScaleItem('Mínimo', '1.0', AppColors.error)),
              const SizedBox(width: 12),
              Expanded(child: _ScaleItem('Básico', '3.0', AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _ScaleItem('Alto', '4.0', AppColors.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _ScaleItem('Superior', '4.6', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _ScaleItem('Máximo', '5.0', AppColors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Escala actual: 1.0 a 5.0 — Aprobación mínima: 3.0', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderInput extends StatefulWidget {
  final double value;
  final Color color;
  const _SliderInput({required this.value, required this.color});

  @override
  State<_SliderInput> createState() => _SliderInputState();
}

class _SliderInputState extends State<_SliderInput> {
  late double _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 4),
            child: Slider(
              value: _val,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: widget.color,
              onChanged: (v) => setState(() => _val = v),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('${_val.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ScaleItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScaleItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
