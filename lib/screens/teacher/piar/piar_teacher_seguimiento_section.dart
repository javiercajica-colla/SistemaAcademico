import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/piar_models.dart';
import '../../../providers/academic_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';

const _kAplicacionLabels = {
  PiarAplicacion.completo: 'Completo',
  PiarAplicacion.parcial: 'Parcial',
  PiarAplicacion.noAplicado: 'No aplicado',
};

const _kCausaLabels = {
  PiarCausaNoAplicacion.faltaMaterialORecurso: 'Faltó material o recurso',
  PiarCausaNoAplicacion.faltaTiempoEnClase: 'Faltó tiempo en la clase',
  PiarCausaNoAplicacion.inasistenciaEstudiante: 'El estudiante no asistió',
  PiarCausaNoAplicacion.ajusteNoPertinente: 'El ajuste no era pertinente',
  PiarCausaNoAplicacion.otra: 'Otra razón',
};

const _kValoracionLabels = {
  PiarValoracion.logradoAutonomia: 'Lo logró con autonomía',
  PiarValoracion.logradoConApoyo: 'Lo logró con apoyo',
  PiarValoracion.enProceso: 'Está en proceso',
  PiarValoracion.sinAvance: 'Sin avance todavía',
};

const _kDecisionLabels = {
  PiarDecisionAjuste.mantener: 'Mantener el ajuste',
  PiarDecisionAjuste.modificar: 'Modificar el ajuste',
  PiarDecisionAjuste.retirar: 'Retirar el ajuste',
  PiarDecisionAjuste.escalar: 'Escalar a coordinación',
};

/// Seguimiento de un ajuste (Fase 7): cómo se aplicó y qué logró el
/// estudiante en el período del ajuste, con la matriz de decisión que
/// sugiere qué hacer a continuación (ver `sugerirDecisionAjuste` en
/// PiarProvider). Solo aparece una vez que el ajuste ya fue enviado o
/// avalado — no tiene sentido hacer seguimiento de una tarea que el
/// docente ni siquiera ha definido todavía.
class PiarTeacherSeguimientoSection extends StatelessWidget {
  const PiarTeacherSeguimientoSection({super.key, required this.ajuste});

  final PiarAjuste ajuste;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final piar = context.watch<PiarProvider>();
    final periodo = academic.periodById(ajuste.periodId);
    final actual = piar.seguimientoActualPara(ajuste.id);
    final periodoAbierto = periodo?.isOpen ?? false;

    if (!periodoAbierto) {
      return _SeguimientoCerrado(ajuste: ajuste, actual: actual);
    }
    return _SeguimientoFormulario(
      key: ValueKey('${ajuste.id}_${actual?.id ?? 'nuevo'}'),
      ajuste: ajuste,
      existente: actual,
    );
  }
}

class _SeguimientoCerrado extends StatefulWidget {
  const _SeguimientoCerrado({required this.ajuste, required this.actual});

  final PiarAjuste ajuste;
  final PiarSeguimiento? actual;

  @override
  State<_SeguimientoCerrado> createState() => _SeguimientoCerradoState();
}

class _SeguimientoCerradoState extends State<_SeguimientoCerrado> {
  bool _corrigiendo = false;

  @override
  Widget build(BuildContext context) {
    if (_corrigiendo) {
      return _SeguimientoFormulario(
        ajuste: widget.ajuste,
        existente: null,
        rectificaA: widget.actual,
      );
    }

    final a = widget.actual;
    if (a == null) {
      return const Text(
        'Este período ya está cerrado y no se registró seguimiento para '
        'este ajuste.',
        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Período cerrado — este seguimiento quedó en solo lectura.',
            style: TextStyle(fontSize: 12.5),
          ),
        ),
        _SoloLectura(seguimiento: a),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_note_rounded, size: 16),
          label: const Text('Registrar corrección'),
          onPressed: () => setState(() => _corrigiendo = true),
        ),
      ],
    );
  }
}

class _SoloLectura extends StatelessWidget {
  const _SoloLectura({required this.seguimiento});

  final PiarSeguimiento seguimiento;

  @override
  Widget build(BuildContext context) {
    final s = seguimiento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Aplicación', _kAplicacionLabels[s.aplicacion]!),
        _row('Valoración', _kValoracionLabels[s.valoracion]!),
        _row('Qué logró', s.queLogro),
        _row('Qué sigue', s.queSigue),
        _row('Decisión', _kDecisionLabels[s.decisionAjuste]!),
      ],
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _SeguimientoFormulario extends StatefulWidget {
  const _SeguimientoFormulario({
    super.key,
    required this.ajuste,
    required this.existente,
    this.rectificaA,
  });

  final PiarAjuste ajuste;
  final PiarSeguimiento? existente;
  /// Si viene con valor, este formulario crea una corrección de un
  /// registro de un período ya cerrado (ver `_SeguimientoCerrado`).
  final PiarSeguimiento? rectificaA;

  @override
  State<_SeguimientoFormulario> createState() => _SeguimientoFormularioState();
}

class _SeguimientoFormularioState extends State<_SeguimientoFormulario> {
  PiarAplicacion? _aplicacion;
  PiarCausaNoAplicacion? _causa;
  PiarValoracion? _valoracion;
  Set<String> _apoyosUsados = {};
  late final TextEditingController _queLogroCtrl;
  late final TextEditingController _conQueApoyoCtrl;
  late final TextEditingController _queSigueCtrl;
  PiarDecisionAjuste? _decision;
  bool _decisionTocadaManualmente = false;
  late final TextEditingController _nuevaRedaccionCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final base = widget.existente ?? widget.rectificaA;
    _aplicacion = widget.existente?.aplicacion;
    _causa = widget.existente?.causaNoAplicacion;
    _valoracion = widget.existente?.valoracion;
    _apoyosUsados = Set.of(widget.existente?.apoyosEfectivamenteUsadosIds ?? const []);
    _decision = widget.existente?.decisionAjuste;
    _queLogroCtrl = TextEditingController(text: widget.existente?.queLogro ?? '');
    _conQueApoyoCtrl = TextEditingController(text: widget.existente?.conQueApoyo ?? '');
    _queSigueCtrl = TextEditingController(text: widget.existente?.queSigue ?? '');
    _nuevaRedaccionCtrl = TextEditingController(
      text: widget.existente?.nuevaRedaccion ?? '',
    );
    if (widget.rectificaA != null && base != null) {
      // Punto de partida de la corrección: lo último registrado, para que
      // el docente solo ajuste lo que estaba mal en vez de partir de cero.
      _aplicacion = base.aplicacion;
      _causa = base.causaNoAplicacion;
      _valoracion = base.valoracion;
      _apoyosUsados = Set.of(base.apoyosEfectivamenteUsadosIds ?? const []);
      _decision = base.decisionAjuste;
      _queLogroCtrl.text = base.queLogro;
      _conQueApoyoCtrl.text = base.conQueApoyo;
      _queSigueCtrl.text = base.queSigue;
      _nuevaRedaccionCtrl.text = base.nuevaRedaccion ?? '';
    }
  }

  @override
  void dispose() {
    _queLogroCtrl.dispose();
    _conQueApoyoCtrl.dispose();
    _queSigueCtrl.dispose();
    _nuevaRedaccionCtrl.dispose();
    super.dispose();
  }

  void _actualizarSugerenciaDecision() {
    if (_decisionTocadaManualmente) return;
    if (_aplicacion != null && _valoracion != null) {
      setState(() => _decision = sugerirDecisionAjuste(_aplicacion!, _valoracion!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final piar = context.watch<PiarProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.rectificaA != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Estás registrando una corrección. El registro original de '
              'este período no se modifica, queda esta nueva versión como '
              'la vigente.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        const Text(
          '¿Cómo se aplicó el ajuste este período?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PiarAplicacion.values.map((a) {
            return ChoiceChip(
              label: Text(_kAplicacionLabels[a]!),
              selected: _aplicacion == a,
              onSelected: (_) => setState(() {
                _aplicacion = a;
                if (a == PiarAplicacion.completo) _causa = null;
                _actualizarSugerenciaDecision();
              }),
            );
          }).toList(),
        ),
        if (_aplicacion != null && _aplicacion != PiarAplicacion.completo) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<PiarCausaNoAplicacion>(
            initialValue: _causa,
            decoration: const InputDecoration(
              labelText: '¿Por qué no se aplicó completo?',
            ),
            items: PiarCausaNoAplicacion.values
                .map(
                  (c) =>
                      DropdownMenuItem(value: c, child: Text(_kCausaLabels[c]!)),
                )
                .toList(),
            onChanged: (v) => setState(() => _causa = v),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          '¿Cómo valoras el progreso del estudiante en esta competencia?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PiarValoracion.values.map((v) {
            return ChoiceChip(
              label: Text(_kValoracionLabels[v]!),
              selected: _valoracion == v,
              onSelected: (_) => setState(() {
                _valoracion = v;
                _actualizarSugerenciaDecision();
              }),
            );
          }).toList(),
        ),
        if (_valoracion == PiarValoracion.logradoConApoyo) ...[
          const SizedBox(height: 12),
          const Text(
            '¿Con qué apoyos lo logró?',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: piar.catalogoApoyos.map((a) {
              final sel = _apoyosUsados.contains(a.id);
              return FilterChip(
                label: Text(a.nombre),
                selected: sel,
                onSelected: (v) => setState(() {
                  if (v) {
                    _apoyosUsados.add(a.id);
                  } else {
                    _apoyosUsados.remove(a.id);
                  }
                }),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _queLogroCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: '¿Qué logró el estudiante este período?',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _conQueApoyoCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: '¿Con qué apoyo lo logró?',
            helperText: 'Si no necesitó apoyo, puedes dejarlo en blanco.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _queSigueCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: '¿Qué sigue para el próximo período?',
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '¿Qué se hace con el ajuste?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        if (_decision != null && !_decisionTocadaManualmente) ...[
          const SizedBox(height: 4),
          const Text(
            'Sugerido según tu respuesta — puedes cambiarlo.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PiarDecisionAjuste.values.map((d) {
            return ChoiceChip(
              label: Text(_kDecisionLabels[d]!),
              selected: _decision == d,
              onSelected: (_) => setState(() {
                _decision = d;
                _decisionTocadaManualmente = true;
              }),
            );
          }).toList(),
        ),
        if (_decision == PiarDecisionAjuste.modificar) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _nuevaRedaccionCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nueva redacción del ajuste',
              helperText: 'Obligatorio cuando decides modificar el ajuste.',
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.save_rounded, size: 16),
          label: Text(_guardando ? 'Guardando…' : 'Guardar seguimiento'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.teacher),
          onPressed: _guardando ? null : _guardar,
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final error = _validar();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _guardando = true);
    final piar = context.read<PiarProvider>();
    final uid = context.read<AuthProvider>().currentUser!.id;
    final now = DateTime.now();
    final esRectificacion = widget.rectificaA != null;
    final id = esRectificacion ? const Uuid().v4() : (widget.existente?.id ?? const Uuid().v4());

    await piar.guardarSeguimiento(
      PiarSeguimiento(
        id: id,
        ajusteId: widget.ajuste.id,
        docenteResponsableId: widget.ajuste.docenteResponsableId,
        periodId: widget.ajuste.periodId,
        aplicacion: _aplicacion!,
        causaNoAplicacion: _aplicacion == PiarAplicacion.completo ? null : _causa,
        valoracion: _valoracion!,
        apoyosEfectivamenteUsadosIds: _valoracion == PiarValoracion.logradoConApoyo
            ? _apoyosUsados.toList()
            : null,
        queLogro: _queLogroCtrl.text.trim(),
        conQueApoyo: _conQueApoyoCtrl.text.trim(),
        queSigue: _queSigueCtrl.text.trim(),
        decisionAjuste: _decision!,
        nuevaRedaccion: _decision == PiarDecisionAjuste.modificar
            ? _nuevaRedaccionCtrl.text.trim()
            : null,
        esRectificacion: esRectificacion,
        rectificaARegistroId: widget.rectificaA?.id,
        creadoPor: widget.existente?.creadoPor ?? uid,
        creadoEn: widget.existente?.creadoEn ?? now,
        actualizadoPor: uid,
        actualizadoEn: now,
      ),
    );

    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seguimiento guardado.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  String? _validar() {
    if (_aplicacion == null) return 'Indica cómo se aplicó el ajuste este período.';
    if (_aplicacion != PiarAplicacion.completo && _causa == null) {
      return 'Indica por qué no se aplicó completo.';
    }
    if (_valoracion == null) return 'Indica cómo valoras el progreso del estudiante.';
    if (_valoracion == PiarValoracion.logradoConApoyo && _apoyosUsados.isEmpty) {
      return 'Indica con qué apoyos lo logró.';
    }
    if (_queLogroCtrl.text.trim().isEmpty) {
      return 'Cuéntanos qué logró el estudiante este período.';
    }
    if (_queSigueCtrl.text.trim().isEmpty) {
      return 'Indica qué sigue para el próximo período.';
    }
    if (_decision == null) return 'Indica qué se hace con el ajuste.';
    if (_decision == PiarDecisionAjuste.modificar &&
        _nuevaRedaccionCtrl.text.trim().isEmpty) {
      return 'Escribe la nueva redacción del ajuste.';
    }
    return null;
  }
}
