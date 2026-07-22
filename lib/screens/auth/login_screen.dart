import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _selectedDemo;
  bool _loggingInAs = false;

  static const _demoAccounts = [
    _DemoAccount(
      email: 'coordinador@colegio.edu.co',
      label: 'Coordinador',
      name: 'Dra. Patricia Morales',
      role: UserRole.coordinator,
      icon: Icons.admin_panel_settings_rounded,
    ),
    _DemoAccount(
      email: 'admin@colegio.edu.co',
      label: 'Administrador',
      name: 'Ing. Andrés Salazar',
      role: UserRole.admin,
      icon: Icons.shield_rounded,
    ),
    _DemoAccount(
      email: 'docente@colegio.edu.co',
      label: 'Docente',
      name: 'Prof. Carlos Rodríguez',
      role: UserRole.teacher,
      icon: Icons.school_rounded,
    ),
    _DemoAccount(
      email: 'estudiante@colegio.edu.co',
      label: 'Estudiante',
      name: 'Juan Pérez García',
      role: UserRole.student,
      icon: Icons.person_rounded,
    ),
    _DemoAccount(
      email: 'padre@colegio.edu.co',
      label: 'Padre',
      name: 'Roberto Pérez',
      role: UserRole.parent,
      icon: Icons.family_restroom_rounded,
    ),
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Correo o contraseña incorrectos'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _quickLogin(_DemoAccount acc) async {
    setState(() {
      _selectedDemo = acc.email;
      _loggingInAs = true;
    });
    _emailCtrl.text = acc.email;
    _passCtrl.text = '123456';
    await context.read<AuthProvider>().login(acc.email, '123456');
    if (mounted) setState(() => _loggingInAs = false);
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return AppColors.coordinator;
      case UserRole.admin:
        return AppColors.purple;
      case UserRole.teacher:
        return AppColors.teacher;
      case UserRole.student:
        return AppColors.student;
      case UserRole.parent:
        return AppColors.parent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _wideLayout(auth) : _narrowLayout(auth),
    );
  }

  // ─── Layouts ──────────────────────────────────────────────────────────────

  Widget _wideLayout(AuthProvider auth) {
    return Row(
      children: [
        _leftPanel(),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _formCard(auth, compact: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(AuthProvider auth) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        32,
      ),
      child: Column(
        children: [
          // Logo en la parte superior del scroll, compacto
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Image.asset(
              'assets/images/logo.png',
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
          _formCard(auth, compact: true),
        ],
      ),
    );
  }

  // ─── Left panel (desktop only) ────────────────────────────────────────────

  Widget _leftPanel() {
    return Container(
      width: 420,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Gestión\nAcadémica\nIntegral',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Plataforma completa para la administración de colegios con evaluación por competencias.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            ..._features(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.secondary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Multi-institución · Seguro · Escalable',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _features() {
    const items = [
      (Icons.assessment_rounded, 'Evaluación por estándares y competencias'),
      (Icons.bar_chart_rounded, 'Dashboards analíticos por rol'),
      (Icons.picture_as_pdf_rounded, 'Boletines automáticos en PDF'),
      (Icons.chat_rounded, 'Mensajería interna entre perfiles'),
      (Icons.security_rounded, 'Acceso seguro con roles diferenciados'),
    ];
    return items
        .map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(f.$1, color: AppColors.primaryLight, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.$2,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  // ─── Form card ────────────────────────────────────────────────────────────

  Widget _formCard(AuthProvider auth, {required bool compact}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 24 : 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Encabezado compacto ──
          _compactHeader(compact),
          SizedBox(height: compact ? 24 : 28),

          // ── Formulario ──
          _buildForm(auth),
          SizedBox(height: compact ? 20 : 24),

          // ── Divisor ──
          _buildDivider(),
          SizedBox(height: compact ? 16 : 20),

          // ── Acceso rápido ──
          _buildQuickAccess(auth, compact),
        ],
      ),
    );
  }

  Widget _compactHeader(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ingresa tus credenciales para acceder',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ─── Form ─────────────────────────────────────────────────────────────────

  Widget _buildForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14),
            decoration: _fieldDecoration(
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
          ),
          const SizedBox(height: 14),

          // Contraseña
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: const TextStyle(fontSize: 14),
            decoration: _fieldDecoration(
              label: 'Contraseña',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 20),

          // Botón ingresar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ingresar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // ─── Divider ──────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Acceso rápido',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ],
    );
  }

  // ─── Quick access ─────────────────────────────────────────────────────────

  Widget _buildQuickAccess(AuthProvider auth, bool compact) {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: compact ? 2.6 : 2.3,
          children: _demoAccounts.map((acc) => _roleChip(acc, auth)).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              Text(
                'Contraseña de prueba: ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '123456',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleChip(_DemoAccount acc, AuthProvider auth) {
    final isSelected = _selectedDemo == acc.email;
    final color = _roleColor(acc.role);
    final isLoading = isSelected && (auth.isLoading || _loggingInAs);

    return GestureDetector(
      onTap: isLoading ? null : () => _quickLogin(acc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(acc.icon, color: color, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      acc.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      acc.name,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _DemoAccount {
  final String email;
  final String label;
  final String name;
  final UserRole role;
  final IconData icon;

  const _DemoAccount({
    required this.email,
    required this.label,
    required this.name,
    required this.role,
    required this.icon,
  });
}
