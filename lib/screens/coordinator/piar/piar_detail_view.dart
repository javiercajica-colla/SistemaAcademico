import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../models/piar_models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';
import 'piar_soporte_dialog.dart';

const _kTipoSoporteLabels = {
  PiarTipoSoporte.informePsicologico: 'Informe psicológico',
  PiarTipoSoporte.valoracionMedica: 'Valoración médica',
  PiarTipoSoporte.terapiaOcupacional: 'Terapia ocupacional',
  PiarTipoSoporte.fonoaudiologia: 'Fonoaudiología',
  PiarTipoSoporte.neuropsicologia: 'Neuropsicología',
  PiarTipoSoporte.certificadoDiscapacidad: 'Certificado de discapacidad',
  PiarTipoSoporte.otro: 'Otro',
};

/// Detalle de una inscripción PIAR: soportes externos y perfil de apoyo.
/// Las pestañas de ajustes/seguimiento/consolidado se agregan en fases
/// posteriores.
class PiarDetailView extends StatefulWidget {
  const PiarDetailView({
    super.key,
    required this.inscripcionId,
    required this.onVolver,
  });

  final String inscripcionId;
  final VoidCallback onVolver;

  @override
  State<PiarDetailView> createState() => _PiarDetailViewState();
}

class _PiarDetailViewState extends State<PiarDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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
    final piar = context.watch<PiarProvider>();
    final inscripcion = piar.inscripcionById(widget.inscripcionId);

    if (inscripcion == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta inscripción ya no está disponible.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onVolver,
              child: const Text('Volver al listado'),
            ),
          ],
        ),
      );
    }

    final student = _studentById(academic, inscripcion.studentId);
    final course = academic.courseById(inscripcion.courseId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 24, 14),
          color: AppColors.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onVolver,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.fullName ?? 'Estudiante no encontrado',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${course?.name ?? "—"} · Estado: ${_estadoLabel(inscripcion.estado)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (inscripcion.estado == PiarEstadoInscripcion.borrador)
                FilledButton.icon(
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: const Text('Activar PIAR'),
                  onPressed: piar.puedeActivar(inscripcion.id)
                      ? () => _activar(context, piar, inscripcion)
                      : null,
                ),
            ],
          ),
        ),
        if (inscripcion.estado == PiarEstadoInscripcion.borrador &&
            !piar.puedeActivar(inscripcion.id))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.warning.withValues(alpha: 0.08),
            child: const Text(
              'Para activar el PIAR: registre al menos un soporte externo vigente y complete el perfil de apoyo.',
              style: TextStyle(fontSize: 12.5, color: AppColors.warning),
            ),
          ),
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Soportes externos'),
              Tab(text: 'Perfil de apoyo'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _SoportesTab(inscripcionId: inscripcion.id),
              _PerfilApoyoTab(inscripcionId: inscripcion.id),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _activar(
    BuildContext context,
    PiarProvider piar,
    PiarInscripcion inscripcion,
  ) async {
    final academic = context.read<AcademicProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;

    // Resuelve automáticamente la carga académica del curso: qué docentes
    // dictan clase a este estudiante y qué competencias (estándares) ya
    // están registradas en cada una de sus asignaturas para el período
    // actual — no se pide selección manual de docentes.
    final periodId =
        academic.currentOpenPeriod?.id ?? academic.activePeriods.firstOrNull?.id;
    if (periodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un período académico activo para activar el PIAR.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final asignaciones = academic.assignments
        .where((a) => a.courseId == inscripcion.courseId)
        .toList();

    final docentesDeLaCarga = <PiarDocenteCarga>[];
    final competenciasPendientes = <PiarCompetenciaPendiente>[];
    for (final asign in asignaciones) {
      final teacher = academic.teacherById(asign.teacherId);
      if (teacher == null) continue;
      docentesDeLaCarga.add((teacherId: teacher.id, userId: teacher.userId));
      for (final std
          in academic.standardsForSubjectAndPeriod(asign.subjectId, periodId)) {
        competenciasPendientes.add((
          subjectId: asign.subjectId,
          standardId: std.id,
          competenciaTextoOriginal: std.description,
          docenteResponsableId: teacher.id,
        ));
      }
    }

    final resultado = await piar.activarInscripcion(
      inscripcion.id,
      uid,
      docentesDeLaCarga: docentesDeLaCarga,
      competenciasPendientes: competenciasPendientes,
      periodId: periodId,
    );
    if (!context.mounted) return;
    if (resultado == PiarAccionResultado.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIAR activado.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else if (resultado == PiarAccionResultado.yaExisteInscripcionActiva) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ya existe otra inscripción activa para este estudiante en este año lectivo.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Faltan requisitos: un soporte externo vigente y el perfil de apoyo completo.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Student? _studentById(AcademicProvider academic, String id) {
    try {
      return academic.students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static String _estadoLabel(PiarEstadoInscripcion e) => switch (e) {
    PiarEstadoInscripcion.borrador => 'Borrador',
    PiarEstadoInscripcion.activo => 'Activo',
    PiarEstadoInscripcion.cerrado => 'Cerrado',
  };
}

// ─── Soportes externos ──────────────────────────────────────────────────

class _SoportesTab extends StatelessWidget {
  const _SoportesTab({required this.inscripcionId});

  final String inscripcionId;

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    final soportes = piar.soportesFor(inscripcionId);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Soportes externos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Agregar soporte'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      PiarSoporteDialog(inscripcionId: inscripcionId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (soportes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'Sin soportes registrados todavía.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: soportes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = soportes[i];
                  return AppCard(
                    child: Row(
                      children: [
                        Icon(
                          s.vigente
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          color: s.vigente
                              ? AppColors.secondary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _kTipoSoporteLabels[s.tipo]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${s.entidadEmisora} · ${s.profesional}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                s.vigente
                                    ? 'Vigente hasta ${_fmt(s.vigenciaHasta)}'
                                    : 'Venció el ${_fmt(s.vigenciaHasta)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: s.vigente
                                      ? AppColors.textSecondary
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => PiarSoporteDialog(
                              inscripcionId: inscripcionId,
                              existente: s,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Perfil de apoyo ────────────────────────────────────────────────────

class _PerfilApoyoTab extends StatefulWidget {
  const _PerfilApoyoTab({required this.inscripcionId});

  final String inscripcionId;

  @override
  State<_PerfilApoyoTab> createState() => _PerfilApoyoTabState();
}

class _PerfilApoyoTabState extends State<_PerfilApoyoTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fortalezasCtrl;
  late final TextEditingController _comoAprendeCtrl;
  late final TextEditingController _barrerasCtrl;
  late final TextEditingController _canalAccesoCtrl;
  late final TextEditingController _formaRespuestaCtrl;
  late final TextEditingController _tiempoAtencionCtrl;
  late final TextEditingController _alertasAulaCtrl;
  Set<String> _apoyosSeleccionados = {};
  bool _inicializado = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fortalezasCtrl = TextEditingController();
    _comoAprendeCtrl = TextEditingController();
    _barrerasCtrl = TextEditingController();
    _canalAccesoCtrl = TextEditingController();
    _formaRespuestaCtrl = TextEditingController();
    _tiempoAtencionCtrl = TextEditingController();
    _alertasAulaCtrl = TextEditingController();
  }

  void _cargarSiHaceFalta(PiarPerfilApoyo? perfil) {
    if (_inicializado) return;
    _inicializado = true;
    if (perfil == null) return;
    _fortalezasCtrl.text = perfil.fortalezas;
    _comoAprendeCtrl.text = perfil.comoAprendeMejor;
    _barrerasCtrl.text = perfil.barrerasIdentificadas;
    _canalAccesoCtrl.text = perfil.canalAccesoPreferente;
    _formaRespuestaCtrl.text = perfil.formaRespuestaPreferente;
    _tiempoAtencionCtrl.text = perfil.tiempoAtencionSostenidaMinutos > 0
        ? '${perfil.tiempoAtencionSostenidaMinutos}'
        : '';
    _alertasAulaCtrl.text = perfil.alertasAula ?? '';
    _apoyosSeleccionados = perfil.apoyosRequeridosIds.toSet();
  }

  @override
  void dispose() {
    _fortalezasCtrl.dispose();
    _comoAprendeCtrl.dispose();
    _barrerasCtrl.dispose();
    _canalAccesoCtrl.dispose();
    _formaRespuestaCtrl.dispose();
    _tiempoAtencionCtrl.dispose();
    _alertasAulaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    final perfil = piar.perfilFor(widget.inscripcionId);
    _cargarSiHaceFalta(perfil);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil de apoyo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Esto es lo único que verá el docente: barreras y apoyos, sin informes ni diagnósticos.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _field(_fortalezasCtrl, 'Fortalezas del estudiante'),
            _field(_comoAprendeCtrl, '¿Cómo aprende mejor?'),
            _field(_barrerasCtrl, 'Barreras identificadas'),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _canalAccesoCtrl,
                    'Canal de acceso preferente',
                    helper: 'Ej. visual, auditivo, táctil',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _formaRespuestaCtrl,
                    'Forma de respuesta preferente',
                    helper: 'Ej. oral, escrita, señalar',
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 260,
              child: TextFormField(
                controller: _tiempoAtencionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de atención sostenida (minutos)',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apoyos requeridos',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: piar.catalogoApoyos.map((a) {
                final sel = _apoyosSeleccionados.contains(a.id);
                return FilterChip(
                  label: Text(a.nombre),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _apoyosSeleccionados.add(a.id);
                    } else {
                      _apoyosSeleccionados.remove(a.id);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field(
              _alertasAulaCtrl,
              'Alertas de aula (información operativa)',
              helper:
                  'Ej. crisis, medicación en jornada, posicionamiento, restricciones físicas. Sin diagnósticos.',
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(_guardando ? 'Guardando…' : 'Guardar perfil'),
              onPressed: _guardando ? null : _guardar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? helper,
    int maxLines = 2,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, helperText: helper),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
            : null,
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final piar = context.read<PiarProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    final existente = piar.perfilFor(widget.inscripcionId);
    final now = DateTime.now();

    await piar.guardarPerfilApoyo(
      PiarPerfilApoyo(
        id: existente?.id ?? const Uuid().v4(),
        inscripcionId: widget.inscripcionId,
        fortalezas: _fortalezasCtrl.text.trim(),
        comoAprendeMejor: _comoAprendeCtrl.text.trim(),
        barrerasIdentificadas: _barrerasCtrl.text.trim(),
        canalAccesoPreferente: _canalAccesoCtrl.text.trim(),
        formaRespuestaPreferente: _formaRespuestaCtrl.text.trim(),
        tiempoAtencionSostenidaMinutos:
            int.tryParse(_tiempoAtencionCtrl.text.trim()) ?? 0,
        apoyosRequeridosIds: _apoyosSeleccionados.toList(),
        alertasAula: _alertasAulaCtrl.text.trim().isEmpty
            ? null
            : _alertasAulaCtrl.text.trim(),
        creadoPor: existente?.creadoPor ?? uid,
        creadoEn: existente?.creadoEn ?? now,
        actualizadoPor: uid,
        actualizadoEn: now,
      ),
    );

    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil de apoyo guardado.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}
