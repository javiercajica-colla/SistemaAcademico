import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

class HojaDeVidaTeacherScreen extends StatefulWidget {
  const HojaDeVidaTeacherScreen({super.key});

  @override
  State<HojaDeVidaTeacherScreen> createState() =>
      _HojaDeVidaTeacherScreenState();
}

class _HojaDeVidaTeacherScreenState extends State<HojaDeVidaTeacherScreen> {
  Teacher? _teacher;
  late ExtendedProfile _profile;
  Uint8List? _photoBytes;
  bool _dirty = false;

  // ── Personal controllers ──────────────────────────────────────────────────
  late TextEditingController _primerNombreCtrl;
  late TextEditingController _segundoNombreCtrl;
  late TextEditingController _primerApellidoCtrl;
  late TextEditingController _segundoApellidoCtrl;
  late TextEditingController _documentoCtrl;
  late TextEditingController _ciudadExpedicionCtrl;
  late TextEditingController _ciudadNacimientoCtrl;
  late TextEditingController _fechaNacimientoCtrl;
  late TextEditingController _numHijosCtrl;
  String _tipoDocumento = 'CC';
  String? _tipoSangre;
  String? _sexo;
  String? _estadoCivil;

  // ── Ubicación controllers ─────────────────────────────────────────────────
  late TextEditingController _direccionCtrl;
  late TextEditingController _barrioCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _celularCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _ciudadUbicacionCtrl;

  // ── Salud controllers ─────────────────────────────────────────────────────
  late TextEditingController _sistemaSaludCtrl;
  late TextEditingController _epsArsCtrl;
  String? _regimen;

  // ── Emergencia controllers ────────────────────────────────────────────────
  late TextEditingController _emNombreCtrl;
  late TextEditingController _emParentescoCtrl;
  late TextEditingController _emTelefonoCtrl;
  late TextEditingController _emCelularCtrl;

  // ── Institucional controllers ─────────────────────────────────────────────
  late TextEditingController _fechaVinMagCtrl;
  late TextEditingController _decretoVinMagCtrl;
  late TextEditingController _claseFuncionarioCtrl;
  late TextEditingController _escalafonCtrl;
  late TextEditingController _estadoDocenteCtrl;
  late TextEditingController _maxCargaCtrl;
  late TextEditingController _fechaVinColegioCtrl;
  late TextEditingController _fechaRetiroCtrl;
  late TextEditingController _decretoVinColegioCtrl;
  late TextEditingController _areaEnsenanzaCtrl;
  late TextEditingController _tipoNombramientoCtrl;
  late TextEditingController _horarioLaboralCtrl;
  late TextEditingController _anosFormacionCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    final auth = context.read<AuthProvider>();
    _teacher ??= academic.teacherByUserId(auth.currentUser!.id);
    if (_teacher == null) return;
    _profile = academic.profileFor(_teacher!.id);
    _photoBytes ??= auth.getAvatarBytes(auth.currentUser!.id);
    _initControllers();
  }

  void _initControllers() {
    final t = _teacher!;
    final p = _profile;

    _primerNombreCtrl = TextEditingController(text: t.firstName);
    _segundoNombreCtrl = TextEditingController(text: p.segundoNombre ?? '');
    _primerApellidoCtrl = TextEditingController(text: t.lastName);
    _segundoApellidoCtrl = TextEditingController(text: p.segundoApellido ?? '');
    _documentoCtrl = TextEditingController(text: t.documentId);
    _ciudadExpedicionCtrl = TextEditingController(text: p.ciudadExpedicion ?? '');
    _ciudadNacimientoCtrl = TextEditingController(text: p.ciudadNacimiento ?? '');
    _fechaNacimientoCtrl = TextEditingController(text: p.fechaNacimiento ?? '');
    _numHijosCtrl = TextEditingController(text: p.numHijos ?? '');
    _tipoDocumento = p.tipoDocumento;
    _tipoSangre = p.tipoSangre;
    _sexo = p.sexo;
    _estadoCivil = p.estadoCivil;

    _direccionCtrl = TextEditingController(text: p.direccion ?? '');
    _barrioCtrl = TextEditingController(text: p.barrio ?? '');
    _telefonoCtrl = TextEditingController(text: p.telefono ?? '');
    _celularCtrl = TextEditingController(text: p.celular ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _ciudadUbicacionCtrl = TextEditingController(text: p.ciudadUbicacion ?? '');

    _sistemaSaludCtrl = TextEditingController(text: p.sistemaSalud ?? '');
    _epsArsCtrl = TextEditingController(text: p.epsArs ?? '');
    _regimen = p.regimen;

    _emNombreCtrl = TextEditingController(text: p.emergenciaNombre ?? '');
    _emParentescoCtrl = TextEditingController(text: p.emergenciaParentesco ?? '');
    _emTelefonoCtrl = TextEditingController(text: p.emergenciaTelefono ?? '');
    _emCelularCtrl = TextEditingController(text: p.emergenciaCelular ?? '');

    _fechaVinMagCtrl = TextEditingController(text: p.fechaVinculacionMagisterio ?? '');
    _decretoVinMagCtrl = TextEditingController(text: p.decretoVinculacionMagisterio ?? '');
    _claseFuncionarioCtrl = TextEditingController(text: p.claseFuncionario ?? '');
    _escalafonCtrl = TextEditingController(text: p.escalafon ?? '');
    _estadoDocenteCtrl = TextEditingController(text: p.estadoDocente ?? '');
    _maxCargaCtrl = TextEditingController(text: p.maxCargaHoraria ?? '');
    _fechaVinColegioCtrl = TextEditingController(text: p.fechaVinculacionColegio ?? '');
    _fechaRetiroCtrl = TextEditingController(text: p.fechaRetiroColegio ?? '');
    _decretoVinColegioCtrl = TextEditingController(text: p.decretoVinculacionColegio ?? '');
    _areaEnsenanzaCtrl = TextEditingController(text: p.areaEnsenanza ?? '');
    _tipoNombramientoCtrl = TextEditingController(text: p.tipoNombramiento ?? '');
    _horarioLaboralCtrl = TextEditingController(text: p.horarioLaboral ?? '');
    _anosFormacionCtrl = TextEditingController(text: p.anosFormacionSuperior ?? '');
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
        _primerNombreCtrl, _segundoNombreCtrl, _primerApellidoCtrl,
        _segundoApellidoCtrl, _documentoCtrl, _ciudadExpedicionCtrl,
        _ciudadNacimientoCtrl, _fechaNacimientoCtrl, _numHijosCtrl,
        _direccionCtrl, _barrioCtrl, _telefonoCtrl, _celularCtrl,
        _emailCtrl, _ciudadUbicacionCtrl, _sistemaSaludCtrl, _epsArsCtrl,
        _emNombreCtrl, _emParentescoCtrl, _emTelefonoCtrl, _emCelularCtrl,
        _fechaVinMagCtrl, _decretoVinMagCtrl, _claseFuncionarioCtrl,
        _escalafonCtrl, _estadoDocenteCtrl, _maxCargaCtrl,
        _fechaVinColegioCtrl, _fechaRetiroCtrl, _decretoVinColegioCtrl,
        _areaEnsenanzaCtrl, _tipoNombramientoCtrl, _horarioLaboralCtrl,
        _anosFormacionCtrl,
      ];

  void _save() {
    final academic = context.read<AcademicProvider>();
    final auth = context.read<AuthProvider>();
    if (_teacher == null) return;

    final updated = ExtendedProfile(
      tipoDocumento: _tipoDocumento,
      ciudadExpedicion: _ciudadExpedicionCtrl.text.trim().nullIfEmpty,
      segundoNombre: _segundoNombreCtrl.text.trim().nullIfEmpty,
      segundoApellido: _segundoApellidoCtrl.text.trim().nullIfEmpty,
      ciudadNacimiento: _ciudadNacimientoCtrl.text.trim().nullIfEmpty,
      fechaNacimiento: _fechaNacimientoCtrl.text.trim().nullIfEmpty,
      tipoSangre: _tipoSangre,
      sexo: _sexo,
      estadoCivil: _estadoCivil,
      numHijos: _numHijosCtrl.text.trim().nullIfEmpty,
      direccion: _direccionCtrl.text.trim().nullIfEmpty,
      barrio: _barrioCtrl.text.trim().nullIfEmpty,
      telefono: _telefonoCtrl.text.trim().nullIfEmpty,
      celular: _celularCtrl.text.trim().nullIfEmpty,
      email: _emailCtrl.text.trim().nullIfEmpty,
      ciudadUbicacion: _ciudadUbicacionCtrl.text.trim().nullIfEmpty,
      sistemaSalud: _sistemaSaludCtrl.text.trim().nullIfEmpty,
      regimen: _regimen,
      epsArs: _epsArsCtrl.text.trim().nullIfEmpty,
      emergenciaNombre: _emNombreCtrl.text.trim().nullIfEmpty,
      emergenciaParentesco: _emParentescoCtrl.text.trim().nullIfEmpty,
      emergenciaTelefono: _emTelefonoCtrl.text.trim().nullIfEmpty,
      emergenciaCelular: _emCelularCtrl.text.trim().nullIfEmpty,
      fechaVinculacionMagisterio: _fechaVinMagCtrl.text.trim().nullIfEmpty,
      decretoVinculacionMagisterio: _decretoVinMagCtrl.text.trim().nullIfEmpty,
      claseFuncionario: _claseFuncionarioCtrl.text.trim().nullIfEmpty,
      escalafon: _escalafonCtrl.text.trim().nullIfEmpty,
      estadoDocente: _estadoDocenteCtrl.text.trim().nullIfEmpty,
      maxCargaHoraria: _maxCargaCtrl.text.trim().nullIfEmpty,
      fechaVinculacionColegio: _fechaVinColegioCtrl.text.trim().nullIfEmpty,
      fechaRetiroColegio: _fechaRetiroCtrl.text.trim().nullIfEmpty,
      decretoVinculacionColegio: _decretoVinColegioCtrl.text.trim().nullIfEmpty,
      areaEnsenanza: _areaEnsenanzaCtrl.text.trim().nullIfEmpty,
      tipoNombramiento: _tipoNombramientoCtrl.text.trim().nullIfEmpty,
      horarioLaboral: _horarioLaboralCtrl.text.trim().nullIfEmpty,
      anosFormacionSuperior: _anosFormacionCtrl.text.trim().nullIfEmpty,
    );

    academic.saveProfile(_teacher!.id, updated);
    _profile = updated;

    if (_photoBytes != null) {
      auth.updateAvatar(auth.currentUser!.id, _photoBytes!);
    }

    setState(() => _dirty = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hoja de vida guardada exitosamente'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_teacher == null) {
      return const Center(child: Text('No se encontró perfil de docente.'));
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
          child: Column(
            children: [
              _HvSection(
                title: 'Datos Personales',
                child: _buildPersonal(),
              ),
              _HvSection(
                title: 'Datos Ubicación',
                child: _buildUbicacion(),
              ),
              _HvSection(
                title: 'Datos Institucionales',
                child: _buildInstitucional(),
              ),
              _HvSection(
                title: 'Datos de Salud',
                child: _buildSalud(),
              ),
              _HvSection(
                title: 'Contacto de Emergencia',
                child: _buildEmergencia(),
              ),
            ],
          ),
        ),
        // Floating save bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_dirty)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text('Cambios sin guardar',
                        style: TextStyle(color: Color(0xFFEF6C00), fontSize: 13)),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Guardar Hoja de Vida'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Sections ─────────────────────────────────────────────────────────────

  Widget _buildPersonal() {
    return Column(
      children: [
        // Row 1: Tipo Doc | Documento | Photo (right side)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 2,
            child: Column(children: [
              _fRow([
                _fDropdown('Tipo Documento', _tipoDocumento,
                    ['CC', 'CE', 'TI'], (v) => setState(() { _tipoDocumento = v!; _dirty = true; }),
                    labels: ['Cédula de Ciudadanía', 'Cédula de Extranjería', 'Tarjeta de Identidad']),
                _fText('Documento', _documentoCtrl),
              ]),
              const SizedBox(height: 10),
              _fRow([_fText('Ciudad Expedición', _ciudadExpedicionCtrl, flex: 1)]),
              const SizedBox(height: 10),
              _fRow([
                _fText('Primer Nombre', _primerNombreCtrl),
                _fText('Segundo Nombre', _segundoNombreCtrl),
                _fText('Primer Apellido', _primerApellidoCtrl),
                _fText('Segundo Apellido', _segundoApellidoCtrl),
              ]),
              const SizedBox(height: 10),
              _fRow([_fText('Ciudad de Nacimiento', _ciudadNacimientoCtrl, flex: 1)]),
              const SizedBox(height: 10),
              _fRow([
                _fText('Fecha Nacimiento', _fechaNacimientoCtrl,
                    hint: 'dd/mm/aaaa'),
                _fDropdown('Tipo Sangre', _tipoSangre,
                    ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                    (v) => setState(() { _tipoSangre = v; _dirty = true; })),
                _fDropdown('Sexo', _sexo, ['M', 'F'],
                    (v) => setState(() { _sexo = v; _dirty = true; }),
                    labels: ['Masculino', 'Femenino']),
                _fDropdown('Estado Civil', _estadoCivil,
                    ['Soltero(a)', 'Casado(a)', 'Unión Libre', 'Divorciado(a)', 'Viudo(a)'],
                    (v) => setState(() { _estadoCivil = v; _dirty = true; })),
                _fText('N° Hijos', _numHijosCtrl,
                    inputType: TextInputType.number),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          // Photo column
          SizedBox(
            width: 160,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Fotografía',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 140,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: _photoBytes != null
                      ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 60, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _pickPhoto,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                    child: const Text('Subir foto', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                if (_photoBytes != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() { _photoBytes = null; _dirty = true; }),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 6)),
                      child: const Text('Quitar Foto',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildUbicacion() {
    return Column(children: [
      _fRow([
        _fText('Dirección', _direccionCtrl, required: true, flex: 2),
        _fText('Barrio', _barrioCtrl, required: true),
      ]),
      const SizedBox(height: 10),
      _fRow([
        _fText('Teléfono', _telefonoCtrl, required: true,
            inputType: TextInputType.phone),
        _fText('Celular', _celularCtrl, required: true,
            inputType: TextInputType.phone),
        _fText('Email', _emailCtrl, required: true,
            inputType: TextInputType.emailAddress, flex: 2),
      ]),
      const SizedBox(height: 10),
      _fRow([_fText('Ciudad', _ciudadUbicacionCtrl, flex: 1)]),
    ]);
  }

  Widget _buildInstitucional() {
    return Column(children: [
      _fRow([
        _fText('Fecha Vinculación Magisterio', _fechaVinMagCtrl, hint: 'dd/mm/aaaa'),
        _fText('Decreto Vinculación Magisterio', _decretoVinMagCtrl),
      ]),
      const SizedBox(height: 10),
      _fRow([
        _fText('Clase de Funcionario', _claseFuncionarioCtrl),
        _fText('Escalafón', _escalafonCtrl),
        _fText('Estado', _estadoDocenteCtrl),
        _fText('Máx. Carga (h/semana)', _maxCargaCtrl,
            inputType: TextInputType.number),
      ]),
      const SizedBox(height: 10),
      _fRow([
        _fText('Fecha Vinculación Colegio', _fechaVinColegioCtrl, hint: 'dd/mm/aaaa'),
        _fText('Fecha Retiro Colegio', _fechaRetiroCtrl, hint: 'dd/mm/aaaa'),
        _fText('Decreto Vinculación Colegio', _decretoVinColegioCtrl),
      ]),
      const SizedBox(height: 10),
      _fRow([
        _fText('Área Enseñanza / Nombramiento', _areaEnsenanzaCtrl, flex: 2),
        _fText('Tipo Nombramiento', _tipoNombramientoCtrl),
      ]),
      const SizedBox(height: 10),
      _fRow([
        _fText('Horario Laboral', _horarioLaboralCtrl),
        _fText('Años Formación Superior', _anosFormacionCtrl,
            inputType: TextInputType.number),
      ]),
    ]);
  }

  Widget _buildSalud() {
    return Column(children: [
      _fRow([
        _fText('Sistema de Salud', _sistemaSaludCtrl),
        _fDropdown('Régimen', _regimen, ['Contributivo', 'Subsidiado', 'Especial', 'Exceptuado'],
            (v) => setState(() { _regimen = v; _dirty = true; })),
        _fText('EPS / ARS', _epsArsCtrl, flex: 2),
      ]),
    ]);
  }

  Widget _buildEmergencia() {
    return Column(children: [
      _fRow([
        _fText('Nombre Completo', _emNombreCtrl, flex: 2),
        _fText('Parentesco', _emParentescoCtrl),
      ]),
      const SizedBox(height: 10),
      _fRow([
        _fText('Teléfono', _emTelefonoCtrl, inputType: TextInputType.phone),
        _fText('Celular', _emCelularCtrl, inputType: TextInputType.phone),
      ]),
    ]);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result?.files.single.bytes != null) {
      setState(() {
        _photoBytes = result!.files.single.bytes;
        _dirty = true;
      });
    }
  }

  Widget _fRow(List<Widget> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .expand((f) => [f, const SizedBox(width: 10)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _fText(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int flex = 1,
    TextInputType inputType = TextInputType.text,
    String? hint,
  }) {
    return Expanded(
      flex: flex,
      child: _HvField(
        label: label,
        required: required,
        child: TextField(
          controller: ctrl,
          keyboardType: inputType,
          onChanged: (_) => setState(() => _dirty = true),
          decoration: _inputDec(hint: hint),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _fDropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    List<String>? labels,
  }) {
    return Expanded(
      child: _HvField(
        label: label,
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          underline: Container(
            height: 1,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          items: options.asMap().entries.map((e) {
            final display = labels != null ? labels[e.key] : e.value;
            return DropdownMenuItem(value: e.value, child: Text(display));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _inputDec({String? hint}) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      );
}

// ─── Shared widgets ────────────────────────────────────────────────────────

class _HvSection extends StatefulWidget {
  final String title;
  final Widget child;

  const _HvSection({required this.title, required this.child});

  @override
  State<_HvSection> createState() => _HvSectionState();
}

class _HvSectionState extends State<_HvSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            color: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: widget.child,
          ),
        Container(height: 4, color: const Color(0xFFF1F5F9)),
      ],
    );
  }
}

class _HvField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;

  const _HvField({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500),
            children: required
                ? const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w700))
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
