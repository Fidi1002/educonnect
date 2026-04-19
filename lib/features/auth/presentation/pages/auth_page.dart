import 'package:educonnect/core/config/app_config.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/services/auth_error_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  static const routeName = 'auth';
  static const routePath = '/auth';

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'EduConnect',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temukan tutor terbaik untuk perjalanan belajarmu.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Masuk'),
                      Tab(text: 'Daftar'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginTab(isLoading: isLoading),
                        _buildRegisterTab(isLoading: isLoading),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab({required bool isLoading}) {
    return ListView(
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading ? null : _onLoginPressed,
          child: Text(isLoading ? 'Memproses...' : 'Masuk'),
        ),
        if (AppConfig.enableGoogleAuth) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _onGooglePressed,
            icon: const Icon(Icons.login),
            label: const Text('Lanjut dengan Google'),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : _onForgotPasswordPressed,
            child: const Text('Lupa Password?'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab({required bool isLoading}) {
    return ListView(
      children: [
        TextField(
          controller: _registerNameController,
          decoration: const InputDecoration(
            labelText: 'Nama lengkap',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password (min 6 karakter)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading ? null : _onRegisterPressed,
          child: Text(isLoading ? 'Memproses...' : 'Buat Akun'),
        ),
      ],
    );
  }

  Future<void> _onLoginPressed() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }

    await _handleAuthAction(() {
      return ref
          .read(authControllerProvider)
          .signInWithEmail(email: email, password: password);
    });
  }

  Future<void> _onRegisterPressed() async {
    final fullName = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Nama, email, dan password wajib diisi.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password minimal 6 karakter.');
      return;
    }

    await _handleAuthAction(() {
      return ref
          .read(authControllerProvider)
          .registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          );
    });
  }

  Future<void> _onGooglePressed() async {
    await _handleAuthAction(() {
      return ref.read(authControllerProvider).signInWithGoogle();
    });
  }

  Future<void> _onForgotPasswordPressed() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Masukkan email dulu untuk reset password.');
      return;
    }

    await _handleAuthAction(() async {
      await ref.read(authControllerProvider).sendPasswordReset(email);
      _showMessage('Link reset password sudah dikirim ke email kamu.');
    });
  }

  Future<void> _handleAuthAction(Future<void> Function() action) async {
    final controller = ref.read(authControllerProvider);
    try {
      await controller.runAuthTask(action);
    } on Exception catch (error) {
      _showMessage(AuthErrorMapper.messageFrom(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
