import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../models/piar_models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';
import '../../../widgets/stat_card.dart';

const _kTipoAjusteLabels = {
  PiarTipoAjuste.acceso: 'De acceso',
  PiarTipoAjuste.metodologico: 'Metodológico',
  PiarTipoAjuste.evaluativo: 'Evaluativo',
  PiarTipoAjuste.significativo: 'Significativo',
};

const _kTipoAjusteHelp = {
  PiarTipoAjuste.acceso:
      'Cambios en el material o el entorno: letra más grande, ubicación en el aula, más tiempo.',
  PiarTipoAjuste.metodologico:
      'Cambios en cómo enseñas: instrucciones más simples, apoyos visuales, pasos más cortos.',
  PiarTipoAjuste.evaluativo:
      'Cambios en cómo evalúas: más tiempo, otro formato de prueba, respuesta oral en vez de escrita.',
  PiarTipoAjuste.significativo:
      'El estudiante trabajará una meta distinta a la del resto del curso. Necesitas explicar por qué.',
};

/// Pantalla de ajustes del docente (Fase 5): encabezado fijo con el perfil
/// de apoyo (solo barreras y apoyos, nunca soportes externos) y una fila
/// expandible por cada competencia a cargo de este docente en esta
/// inscripción. Un docente que manipule el id de la URL no llega aquí con
/// datos de otra asignatura: `PiarProvider.ajustesForDocente` ya filtra por
/// `docenteResponsableId == teacher.id`.
class PiarTeacherAjustesView extends StatelessWidget {
  const PiarTeacherAjustesView({
    super.key,
    required this.inscripcionId,
    required this.teacher,
    required this.onVolver,
  });

  final String inscripcionId;
  final Teacher teacher;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    final inscripcion = piar.inscripcionById(inscripcionId);

    if (inscripcion == null ||
        inscripcion.estado != PiarEstadoInscripcion.activo) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Este PIAR ya no está disponible.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onVolver, child: const Text('Volver')),
          ],
        ),
      );
    }

    final ajustes = piar.ajustesForDocente(inscripcionId, teacher.id);
    if (ajustes.isEmpty) {
      // Un docente que manipule el id de otro estudiante sin tener
      // competencias asignadas en esa inscripción no ve nada — bloqueo de
      // datos, no solo de navegación.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No tienes competencias asignadas en este PIAR.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onVolver, child: const Text('Volver')),
          ],
        ),
      );
    }

    final perfil = piar.perfilFor(inscripcionId);
    final student = _studentById(academic, inscripcion.studentId);
    final course = academic.courseById(inscripcion.courseId);

    final porAsignatura = <String, List<PiarAjuste>>{};
    for (final a in ajustes) {
      porAsignatura.putIfAbsent(a.subjectId, () => []).add(a);
    }

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
                onPressed: onVolver,
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
                      course?.name ?? '—',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _PerfilApoyoReadOnlyCard(perfil: perfil),
              const SizedBox(height: 20),
              const Text(
                'Ajustes por competencia',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Para cada estándar de tu asignatura, define si este '
                'estudiante necesita un ajuste y cuál. Se guarda '
                'automáticamente mientras escribes.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              for (final subjectId in porAsignatura.keys) ...[
                Text(
                  academic.subjectById(subjectId)?.name ?? 'Asignatura',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.teacher,
                  ),
                ),
                const SizedBox(height: 8),
                for (final ajuste in porAsignatura[subjectId]!) ...[
                  _AjusteFormCard(
                    key: ValueKey(ajuste.id),
                    ajuste: ajuste,
                    standardName: _standardName(academic, ajuste.standardId),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Student? _studentById(AcademicProvider academic, String id) {
    try {
      return academic.students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  String _standardName(AcademicProvider academic, String standardId) {
    try {
      return academic.standards.firstWhere((s) => s.id == standardId).name;
    } catch (_) {
      return 'Competencia';
    }
  }
}

// ─── Perfil de apoyo — solo lectura, encabezado fijo ────────────────────

class _PerfilApoyoReadOnlyCard extends StatelessWidget {
  const _PerfilApoyoReadOnlyCard({required this.perfil});

  final PiarPerfilApoyo? perfil;

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    if (perfil == null) {
      return const AppCard(
        child: Text(
          'Coordinación aún no ha completado el perfil de apoyo de este '
          'estudiante.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    final p = perfil!;
    return AppCard(
      title: 'Perfil de apoyo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esto es lo único que verás de este estudiante: barreras y '
            'apoyos para tu clase, sin informes ni diagnósticos.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _row('Fortalezas', p.fortalezas),
          _row('Cómo aprende mejor', p.comoAprendeMejor),
          _row('Barreras identificadas', p.barrerasIdentificadas),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _row('Canal de acceso', p.canalAccesoPreferente)),
              const SizedBox(width: 16),
              Expanded(
                child: _row('Forma de respuesta', p.formaRespuestaPreferente),
              ),
            ],
          ),
          if (p.tiempoAtencionSostenidaMinutos > 0)
            _row(
              'Atención sostenida',
              '${p.tiempoAtencionSostenidaMinutos} min. aprox.',
            ),
          if (p.apoyosRequeridosIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              'Apoyos requeridos',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.apoyosRequeridosIds
                  .map((id) => piar.apoyoById(id)?.nombre)
                  .whereType<String>()
                  .map(
                    (nombre) => Chip(
                      label: Text(nombre, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.teacher.withValues(alpha: 0.08),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (p.alertasAula != null && p.alertasAula!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.alertasAula!,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(value.isEmpty ? '—' : value),
        ],
      ),
    );
  }
}

// ─── Ajuste por competencia — fila expandible con el formulario ────────

class _AjusteFormCard extends StatefulWidget {
  const _AjusteFormCard({super.key, required this.ajuste, required this.standardName});

  final PiarAjuste ajuste;
  final String standardName;

  @override
  State<_AjusteFormCard> createState() => _AjusteFormCardState();
}

class _AjusteFormCardState extends State<_AjusteFormCard> {
  bool? _requiereAjuste;
  Set<PiarTipoAjuste> _tipos = {};
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _metaMinimaCtrl;
  late final TextEditingController _justificacionCtrl;
  late final TextEditingController _evidenciaCtrl;
  late final TextEditingController _observacionesCtrl;
  Set<String> _apoyosSeleccionados = {};
  bool _sinRevisar = false;
  bool _dirty = false;
  bool _guardando = false;
  bool _expandido = false;
  Timer? _autosaveTimer;

  bool get _editable =>
      widget.ajuste.estado == PiarEstadoAjuste.borrador ||
      widget.ajuste.estado == PiarEstadoAjuste.devuelto;

  @override
  void initState() {
    super.initState();
    _cargarDesde(widget.ajuste);
    _descripcionCtrl = TextEditingController(text: widget.ajuste.descripcionAjuste);
    _metaMinimaCtrl = TextEditingController(text: widget.ajuste.metaMinima);
    _justificacionCtrl = TextEditingController(
      text: widget.ajuste.justificacionSignificativo ?? '',
    );
    _evidenciaCtrl = TextEditingController(text: widget.ajuste.evidenciaEsperada);
    _observacionesCtrl = TextEditingController(text: widget.ajuste.observaciones ?? '');
    _autosaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_dirty && _editable && !_guardando) _guardar(enviar: false, silencioso: true);
    });
  }

  void _cargarDesde(PiarAjuste a) {
    _requiereAjuste = a.requiereAjuste;
    _tipos = Set.of(a.tiposAjuste);
    _apoyosSeleccionados = Set.of(a.apoyosAUtilizarIds);
    _sinRevisar = a.sinRevisar;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _descripcionCtrl.dispose();
    _metaMinimaCtrl.dispose();
    _justificacionCtrl.dispose();
    _evidenciaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.standardName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.ajuste.competenciaTextoOriginal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _estadoChip(),
                  const SizedBox(width: 8),
                  Icon(
                    _expandido
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildForm(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoChip() {
    String label;
    Color color;
    if (_sinRevisar) {
      label = 'Sin revisar';
      color = AppColors.warning;
    } else {
      switch (widget.ajuste.estado) {
        case PiarEstadoAjuste.borrador:
          label = widget.ajuste.requiereAjuste == null ? 'Pendiente' : 'Borrador';
          color = widget.ajuste.requiereAjuste == null
              ? AppColors.warning
              : AppColors.textSecondary;
        case PiarEstadoAjuste.enviado:
          label = 'Enviado';
          color = AppColors.secondary;
        case PiarEstadoAjuste.pendienteAval:
          label = 'Pendiente de aval';
          color = AppColors.primary;
        case PiarEstadoAjuste.avalado:
          label = 'Avalado';
          color = AppColors.secondary;
        case PiarEstadoAjuste.devuelto:
          label = 'Devuelto';
          color = AppColors.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final piar = context.watch<PiarProvider>();
    final anterior = piar.ajusteAnteriorPara(widget.ajuste);
    final significativo = _tipos.contains(PiarTipoAjuste.significativo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sinRevisar)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Esta información se copió del período anterior. Revísala y '
              'guárdala para confirmar que sigue vigente.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estándar / competencia de este período',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(widget.ajuste.competenciaTextoOriginal),
            ],
          ),
        ),
        if (_editable && anterior != null && _requiereAjuste == null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('Copiar del período anterior'),
            onPressed: () => _copiarDelPeriodoAnterior(anterior),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          '¿Este estudiante necesita un ajuste para alcanzar esta competencia?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Sí, necesita un ajuste'),
              selected: _requiereAjuste == true,
              onSelected: _editable
                  ? (v) => setState(() {
                      _requiereAjuste = true;
                      _dirty = true;
                    })
                  : null,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('No, sigue la meta del curso'),
              selected: _requiereAjuste == false,
              onSelected: _editable
                  ? (v) => setState(() {
                      _requiereAjuste = false;
                      _tipos.clear();
                      _metaMinimaCtrl.text = widget.ajuste.competenciaTextoOriginal;
                      _dirty = true;
                    })
                  : null,
            ),
          ],
        ),
        if (_requiereAjuste == true) ...[
          const SizedBox(height: 18),
          const Text(
            '¿Qué tipo de ajuste necesita? (puedes elegir varios)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PiarTipoAjuste.values.map((t) {
              final sel = _tipos.contains(t);
              return FilterChip(
                label: Text(_kTipoAjusteLabels[t]!),
                selected: sel,
                onSelected: _editable
                    ? (v) => setState(() {
                        if (v) {
                          _tipos.add(t);
                        } else {
                          _tipos.remove(t);
                          if (t == PiarTipoAjuste.significativo) {
                            _metaMinimaCtrl.text =
                                widget.ajuste.competenciaTextoOriginal;
                          }
                        }
                        _dirty = true;
                      })
                    : null,
              );
            }).toList(),
          ),
          if (_tipos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _tipos.map((t) => _kTipoAjusteHelp[t]!).join(' '),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 18),
          _field(
            _descripcionCtrl,
            'Describe el ajuste que vas a aplicar en tu clase',
            helper:
                'Sé concreto: qué vas a hacer distinto en el día a día de tu '
                'clase (80 a 600 caracteres). Llevas ${_descripcionCtrl.text.trim().length}.',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _field(
            _metaMinimaCtrl,
            'Meta que el estudiante debe alcanzar',
            helper: significativo
                ? 'Como marcaste "Significativo", puedes redactar una meta '
                    'distinta a la del resto del curso.'
                : 'Es la misma meta del curso. Si el estudiante necesita una '
                    'meta distinta, marca "Significativo" arriba.',
            enabled: significativo,
            maxLines: 2,
          ),
          if (significativo) ...[
            const SizedBox(height: 12),
            _field(
              _justificacionCtrl,
              '¿Por qué esta meta es distinta a la del resto del curso?',
              helper: 'Obligatorio cuando el ajuste es significativo.',
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 12),
          _field(
            _evidenciaCtrl,
            '¿Qué evidencia vas a usar para saber si lo logró?',
            helper:
                'Ej. trabajo escrito, participación oral, portafolio. Mínimo '
                '40 caracteres. Llevas ${_evidenciaCtrl.text.trim().length}.',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Qué apoyos vas a usar para este ajuste?',
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
                onSelected: _editable
                    ? (v) => setState(() {
                        if (v) {
                          _apoyosSeleccionados.add(a.id);
                        } else {
                          _apoyosSeleccionados.remove(a.id);
                        }
                        _dirty = true;
                      })
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _field(
            _observacionesCtrl,
            'Observaciones adicionales (opcional)',
            maxLines: 2,
            required: false,
          ),
        ],
        const SizedBox(height: 18),
        if (!_editable)
          const Text(
            'Este ajuste ya fue enviado y no se puede editar desde aquí.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined, size: 16),
                label: Text(_guardando ? 'Guardando…' : 'Guardar borrador'),
                onPressed: (_dirty && !_guardando)
                    ? () => _guardar(enviar: false)
                    : null,
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Enviar'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teacher),
                onPressed: _guardando ? null : () => _guardar(enviar: true),
              ),
            ],
          ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? helper,
    int maxLines = 2,
    bool required = true,
    bool enabled = true,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      enabled: _editable && enabled,
      decoration: InputDecoration(labelText: label, helperText: helper, helperMaxLines: 2),
      onChanged: (_) => setState(() => _dirty = true),
    );
  }

  void _copiarDelPeriodoAnterior(PiarAjuste anterior) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Copiar del período anterior'),
        content: const Text(
          'Se copiará la información que registraste en el período '
          'anterior para esta misma competencia. Quedará marcada como "sin '
          'revisar" hasta que la guardes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _requiereAjuste = anterior.requiereAjuste;
                _tipos = Set.of(anterior.tiposAjuste);
                _descripcionCtrl.text = anterior.descripcionAjuste;
                _metaMinimaCtrl.text = anterior.metaMinima;
                _justificacionCtrl.text = anterior.justificacionSignificativo ?? '';
                _evidenciaCtrl.text = anterior.evidenciaEsperada;
                _apoyosSeleccionados = Set.of(anterior.apoyosAUtilizarIds);
                _observacionesCtrl.text = anterior.observaciones ?? '';
                _sinRevisar = true;
                _dirty = true;
              });
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar({required bool enviar, bool silencioso = false}) async {
    if (enviar) {
      final error = _validar();
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    }

    setState(() => _guardando = true);
    final piar = context.read<PiarProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    final now = DateTime.now();
    final significativo = _tipos.contains(PiarTipoAjuste.significativo);

    final estado = !enviar
        ? PiarEstadoAjuste.borrador
        : (significativo
              ? PiarEstadoAjuste.pendienteAval
              : PiarEstadoAjuste.enviado);

    await piar.guardarAjuste(
      PiarAjuste(
        id: widget.ajuste.id,
        inscripcionId: widget.ajuste.inscripcionId,
        subjectId: widget.ajuste.subjectId,
        standardId: widget.ajuste.standardId,
        periodId: widget.ajuste.periodId,
        competenciaTextoOriginal: widget.ajuste.competenciaTextoOriginal,
        requiereAjuste: _requiereAjuste,
        tiposAjuste: _tipos,
        descripcionAjuste: _requiereAjuste == true ? _descripcionCtrl.text.trim() : '',
        metaMinima: significativo
            ? _metaMinimaCtrl.text.trim()
            : widget.ajuste.competenciaTextoOriginal,
        justificacionSignificativo: significativo
            ? _justificacionCtrl.text.trim()
            : null,
        evidenciaEsperada: _requiereAjuste == true ? _evidenciaCtrl.text.trim() : '',
        apoyosAUtilizarIds: _requiereAjuste == true
            ? _apoyosSeleccionados.toList()
            : const [],
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),
        docenteResponsableId: widget.ajuste.docenteResponsableId,
        estado: estado,
        sinRevisar: false,
        creadoPor: widget.ajuste.creadoPor,
        creadoEn: widget.ajuste.creadoEn,
        actualizadoPor: uid,
        actualizadoEn: now,
      ),
    );

    if (!mounted) return;
    setState(() {
      _guardando = false;
      _dirty = false;
      _sinRevisar = false;
    });
    if (!silencioso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enviar ? 'Ajuste enviado.' : 'Borrador guardado.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  String? _validar() {
    if (_requiereAjuste == null) {
      return 'Responde si el estudiante necesita un ajuste en esta competencia.';
    }
    if (_requiereAjuste == false) return null;
    if (_tipos.isEmpty) return 'Selecciona al menos un tipo de ajuste.';
    final desc = _descripcionCtrl.text.trim();
    if (desc.length < 80 || desc.length > 600) {
      return 'La descripción del ajuste debe tener entre 80 y 600 caracteres '
          '(tiene ${desc.length}).';
    }
    final evid = _evidenciaCtrl.text.trim();
    if (evid.length < 40) {
      return 'La evidencia esperada debe tener al menos 40 caracteres (tiene '
          '${evid.length}).';
    }
    if (_tipos.contains(PiarTipoAjuste.significativo) &&
        _justificacionCtrl.text.trim().isEmpty) {
      return 'Explica por qué la meta es distinta a la del resto del curso.';
    }
    return null;
  }
}
