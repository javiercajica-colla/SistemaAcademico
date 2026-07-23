import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/piar_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/piar_provider.dart';

const _kTipoSoporteLabels = {
  PiarTipoSoporte.informePsicologico: 'Informe psicológico',
  PiarTipoSoporte.valoracionMedica: 'Valoración médica',
  PiarTipoSoporte.terapiaOcupacional: 'Terapia ocupacional',
  PiarTipoSoporte.fonoaudiologia: 'Fonoaudiología',
  PiarTipoSoporte.neuropsicologia: 'Neuropsicología',
  PiarTipoSoporte.certificadoDiscapacidad: 'Certificado de discapacidad',
  PiarTipoSoporte.otro: 'Otro',
};

/// Formulario de un soporte externo (informe médico/psicológico/etc). Solo
/// visible para coordinación/orientación — nunca para docentes, ni desde
/// esta pantalla ni desde ninguna otra (reforzado en las Firestore rules
/// de la Fase 2).
class PiarSoporteDialog extends StatefulWidget {
  const PiarSoporteDialog({
    super.key,
    required this.inscripcionId,
    this.existente,
  });

  final String inscripcionId;
  final PiarSoporteExterno? existente;

  @override
  State<PiarSoporteDialog> createState() => _PiarSoporteDialogState();
}

class _PiarSoporteDialogState extends State<PiarSoporteDialog> {
  final _formKey = GlobalKey<FormState>();
  late PiarTipoSoporte _tipo;
  late final TextEditingController _entidadCtrl;
  late final TextEditingController _profesionalCtrl;
  late final TextEditingController _registroCtrl;
  late final TextEditingController _archivoCtrl;
  late final TextEditingController _observacionesCtrl;
  DateTime? _fechaEmision;
  DateTime? _vigenciaHasta;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _tipo = e?.tipo ?? PiarTipoSoporte.informePsicologico;
    _entidadCtrl = TextEditingController(text: e?.entidadEmisora ?? '');
    _profesionalCtrl = TextEditingController(text: e?.profesional ?? '');
    _registroCtrl = TextEditingController(
      text: e?.numeroRegistroProfesional ?? '',
    );
    _archivoCtrl = TextEditingController(text: e?.archivoAdjunto ?? '');
    _observacionesCtrl = TextEditingController(text: e?.observaciones ?? '');
    _fechaEmision = e?.fechaEmision;
    _vigenciaHasta = e?.vigenciaHasta;
  }

  @override
  void dispose() {
    _entidadCtrl.dispose();
    _profesionalCtrl.dispose();
    _registroCtrl.dispose();
    _archivoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existente == null
                      ? 'Nuevo soporte externo'
                      : 'Editar soporte externo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<PiarTipoSoporte>(
                          initialValue: _tipo,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: PiarTipoSoporte.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_kTipoSoporteLabels[t]!),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _tipo = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _entidadCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Entidad emisora',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _profesionalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Profesional que emite',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _registroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Número de registro profesional',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'Fecha de emisión',
                                value: _fechaEmision,
                                onChanged: (d) =>
                                    setState(() => _fechaEmision = d),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateField(
                                label: 'Vigencia hasta',
                                value: _vigenciaHasta,
                                onChanged: (d) =>
                                    setState(() => _vigenciaHasta = d),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _archivoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Referencia del archivo (URL u opcional)',
                            helperText:
                                'La carga de archivos aún no está disponible; use un enlace externo si lo tiene.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _observacionesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones (opcional)',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: Text(_guardando ? 'Guardando…' : 'Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaEmision == null || _vigenciaHasta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indique la fecha de emisión y la vigencia.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final uid = context.read<AuthProvider>().currentUser!.id;
    final now = DateTime.now();
    final existente = widget.existente;

    await context.read<PiarProvider>().guardarSoporteExterno(
      PiarSoporteExterno(
        id: existente?.id ?? const Uuid().v4(),
        inscripcionId: widget.inscripcionId,
        tipo: _tipo,
        entidadEmisora: _entidadCtrl.text.trim(),
        profesional: _profesionalCtrl.text.trim(),
        numeroRegistroProfesional: _registroCtrl.text.trim(),
        fechaEmision: _fechaEmision!,
        vigenciaHasta: _vigenciaHasta!,
        archivoAdjunto: _archivoCtrl.text.trim().isEmpty
            ? null
            : _archivoCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),
        creadoPor: existente?.creadoPor ?? uid,
        creadoEn: existente?.creadoEn ?? now,
        actualizadoPor: uid,
        actualizadoEn: now,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null
              ? 'Seleccionar'
              : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}',
        ),
      ),
    );
  }
}
