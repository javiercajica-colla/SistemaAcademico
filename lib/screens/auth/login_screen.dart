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
      label: 'Coordinador Académico',
      name: 'Dra. Patricia Morales',
      role: UserRole.coordinator,
      description: 'Acceso total al sistema, configuración y reportes',
      icon: Icons.admin_panel_settings_rounded,
    ),
    _DemoAccount(
      email: 'docente@colegio.edu.co',
      label: 'Docente',
      name: 'Prof. Carlos Rodríguez',
      role: UserRole.teacher,
      description: 'Calificaciones, asistencia y observaciones',
      icon: Icons.school_rounded,
    ),
    _DemoAccount(
      email: 'estudiante@colegio.edu.co',
      label: 'Estudiante',
      name: 'Juan Pérez García',
      role: UserRole.student,
      description: 'Notas, asistencia y evolución académica',
      icon: Icons.person_rounded,
    ),
    _DemoAccount(
      email: 'padre@colegio.edu.co',
      label: 'Padre de Familia',
      name: 'Roberto Pérez',
      role: UserRole.parent,
      description: 'Seguimiento de hijos y notificaciones',
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
          content: Text(auth.error ?? 'Error al iniciar sesión'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _quickLogin(_DemoAccount acc) async {
    setState(() { _selectedDemo = acc.email; _loggingInAs = true; });
    _emailCtrl.text = acc.email;
    _passCtrl.text = '123456';
    final auth = context.read<AuthProvider>();
    await auth.login(acc.email, '123456');
    if (mounted) setState(() => _loggingInAs = false);
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.coordinator: return AppColors.coordinator;
      case UserRole.teacher:     return AppColors.teacher;
      case UserRole.student:     return AppColors.student;
      case UserRole.parent:      return AppColors.parent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _buildLeftPanel(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildForm(auth),
                      const SizedBox(height: 28),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildQuickAccessCards(auth),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 460,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrand(),
            const Spacer(),
            _buildHeroText(),
            const SizedBox(height: 32),
            ..._buildFeatureList(),
            const Spacer(),
            _buildFooterBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EduGestión Pro', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Sistema Académico Integral', style: TextStyle(color: AppColors.primaryLight, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestión Académica\nIntegral', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, height: 1.2)),
        SizedBox(height: 14),
        Text(
          'Plataforma completa para la administración de colegios. Evaluación por competencias, seguimiento estudiantil y boletines automáticos.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      (Icons.assessment_rounded, 'Evaluación por competencias y estándares'),
      (Icons.bar_chart_rounded, 'Dashboards analíticos por rol'),
      (Icons.picture_as_pdf_rounded, 'Boletines automáticos en PDF'),
      (Icons.notifications_rounded, 'Notificaciones a padres en tiempo real'),
      (Icons.security_rounded, 'Acceso seguro con roles diferenciados'),
    ];
    return features.map((f) => Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Icon(f.$1, color: AppColors.primaryLight, size: 18),
          const SizedBox(width: 10),
          Text(f.$2, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
        ],
      ),
    )).toList();
  }

  Widget _buildFooterBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: AppColors.secondary, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('Multi-institución SaaS • Seguro • Escalable', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Iniciar Sesión', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Ingresa tus credenciales o elige un perfil de prueba', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _login,
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Iniciar Sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Acceso rápido — Usuarios de prueba', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildQuickAccessCards(AuthProvider auth) {
    return Column(
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 100,
          ),
          children: _demoAccounts.map((acc) => _buildRoleCard(acc, auth)).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textTertiary),
              SizedBox(width: 6),
              Text('Contraseña para todos los perfiles: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('123456', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(_DemoAccount acc, AuthProvider auth) {
    final isSelected = _selectedDemo == acc.email;
    final color = _roleColor(acc.role);
    final isLoading = isSelected && (auth.isLoading || _loggingInAs);

    return GestureDetector(
      onTap: isLoading ? null : () => _quickLogin(acc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.07) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
                  child: isLoading
                      ? Padding(padding: const EdgeInsets.all(6), child: CircularProgressIndicator(color: color, strokeWidth: 2))
                      : Icon(acc.icon, color: color, size: 17),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Demo', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(acc.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? color : AppColors.textPrimary)),
            Text(acc.name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _DemoAccount {
  final String email;
  final String label;
  final String name;
  final UserRole role;
  final String description;
  final IconData icon;

  const _DemoAccount({
    required this.email,
    required this.label,
    required this.name,
    required this.role,
    required this.description,
    required this.icon,
  });
}
