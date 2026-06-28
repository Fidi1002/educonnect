import 'dart:ui';
import 'package:educonnect/core/config/app_config.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/data/repositories/auth_repository.dart';
import 'package:educonnect/features/auth/domain/services/auth_error_mapper.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          // Vibrant Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Subtle background decoration
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo or Brand Name
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 56,
                              height: 56,
                            ),
                          ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 16),
                          const Text(
                            'EduConnect',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fade(delay: 300.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                          const SizedBox(height: 8),
                          Text(
                            'Temukan tutor terbaik untuk perjalanan belajarmu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ).animate().fade(delay: 400.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Glassmorphism Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  labelColor: Theme.of(context).colorScheme.primary,
                                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  indicatorColor: Theme.of(context).colorScheme.tertiary,
                                  indicatorWeight: 3,
                                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  tabs: const [
                                    Tab(text: 'Masuk'),
                                    Tab(text: 'Daftar'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 380, // fixed height to prevent unbounded errors in scroll
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
                      ).animate().fade(delay: 500.ms, duration: 500.ms).slideY(begin: 0.1),
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

  Widget _buildLoginTab({required bool isLoading}) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Semantics(
          label: 'Kolom input email masuk',
          textField: true,
          child: TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(FluentIcons.mail_24_regular),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Kolom input password masuk',
          textField: true,
          child: TextFormField(
            controller: _loginPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(FluentIcons.lock_closed_24_regular),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'Tombol masuk akun',
          button: true,
          child: FilledButton(
            onPressed: isLoading ? null : _onLoginPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: Text(isLoading ? 'Memproses...' : 'Masuk', style: const TextStyle(fontSize: 16)),
          ),
        ),
        if (AppConfig.enableGoogleAuth) ...[
          const SizedBox(height: 16),
          Semantics(
            label: 'Tombol masuk menggunakan akun Google',
            button: true,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _onGooglePressed,
              icon: const Icon(FluentIcons.person_24_regular),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text('Lanjut dengan Google'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: Semantics(
            label: 'Tombol lupa password',
            button: true,
            child: TextButton(
              onPressed: isLoading ? null : _onForgotPasswordPressed,
              child: const Text('Lupa Password?'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab({required bool isLoading}) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Semantics(
          label: 'Kolom input nama lengkap pendaftaran',
          textField: true,
          child: TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(FluentIcons.person_24_regular),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Kolom input email pendaftaran',
          textField: true,
          child: TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(FluentIcons.mail_24_regular),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Kolom input password pendaftaran',
          textField: true,
          child: TextFormField(
            controller: _registerPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Minimal 6 karakter',
              prefixIcon: Icon(FluentIcons.lock_closed_24_regular),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'Tombol buat akun baru',
          button: true,
          child: FilledButton(
            onPressed: isLoading ? null : _onRegisterPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(isLoading ? 'Memproses...' : 'Buat Akun', style: const TextStyle(fontSize: 16)),
          ),
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

    final controller = ref.read(authControllerProvider);
    try {
      await controller.runAuthTask(() async {
        await controller.registerWithEmail(
          fullName: fullName,
          email: email,
          password: password,
        );
      });
      
      final hasSession = ref.read(authRepositoryProvider).hasActiveSession;
      if (!hasSession) {
        _showVerificationDialog(email);
      }
    } on Exception catch (error) {
      final mappedMessage = AuthErrorMapper.messageFrom(error);
      if (mappedMessage.contains('verifikasi') || mappedMessage.contains('Cek email')) {
        _showVerificationDialog(email);
      } else {
        _showMessage(mappedMessage);
      }
    }
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

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                FluentIcons.mail_24_regular,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Verifikasi Email'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akun Anda berhasil dibuat!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Kami telah mengirimkan tautan konfirmasi ke email:',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF1377)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Silakan periksa kotak masuk (inbox) atau folder spam Anda dan klik tautan tersebut untuk memverifikasi akun sebelum masuk ke aplikasi.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tabController.animateTo(0); // Switch to login tab
              },
              child: const Text('Saya Mengerti'),
            ),
          ],
        );
      },
    );
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
