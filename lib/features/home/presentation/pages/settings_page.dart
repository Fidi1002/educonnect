import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';

import 'package:educonnect/core/presentation/providers/theme_provider.dart';
import 'package:educonnect/core/presentation/providers/locale_provider.dart';
import 'package:educonnect/core/presentation/localization/app_translations.dart';
import 'package:educonnect/core/presentation/providers/shared_preferences_provider.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const routePath = '/settings';
  static const routeName = 'settings';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double _cacheSizeMb = 0.0;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  // Calculate real cache size in temporary directory
  Future<void> _calculateCacheSize() async {
    setState(() {
      _isLoadingCache = true;
    });
    try {
      final tempDir = await getTemporaryDirectory();
      double totalBytes = 0;
      if (await tempDir.exists()) {
        totalBytes += await _getDirSize(tempDir);
      }
      setState(() {
        _cacheSizeMb = totalBytes / (1024 * 1024);
        _isLoadingCache = false;
      });
    } catch (e) {
      setState(() {
        _cacheSizeMb = 0.0;
        _isLoadingCache = false;
      });
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int total = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list(recursive: true).toList();
      for (final FileSystemEntity entity in entities) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  // Clear cache action
  Future<void> _clearCache(AppTranslations translations) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(translations.clearCacheConfirm),
          content: Text(translations.clearCacheSub),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translations.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  final tempDir = await getTemporaryDirectory();
                  if (await tempDir.exists()) {
                    final List<FileSystemEntity> entities = await tempDir.list().toList();
                    for (final entity in entities) {
                      await entity.delete(recursive: true);
                    }
                  }
                  await _calculateCacheSize();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(translations.clearCacheSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${translations.failed}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(translations.clearCache),
            ),
          ],
        );
      },
    );
  }

  // Language modal sheet selector
  void _showLanguageSelector(BuildContext context, AppTranslations translations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final activeLocale = ref.watch(localeProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    translations.selectLanguage,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Text('🇮🇩', style: TextStyle(fontSize: 28)),
                    title: const Text(
                      'Bahasa Indonesia',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: activeLocale.languageCode == 'id'
                        ? Icon(
                            FluentIcons.checkmark_circle_24_filled,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(const Locale('id'));
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                    title: const Text(
                      'English (US)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: activeLocale.languageCode == 'en'
                        ? Icon(
                            FluentIcons.checkmark_circle_24_filled,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Change Password popup dialog
  void _showChangePasswordDialog(AppTranslations translations) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isSaving = ref.watch(authLoadingProvider);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                translations.changePassword,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: true,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          labelText: translations.oldPassword,
                          prefixIcon: const Icon(FluentIcons.lock_shield_24_regular),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          labelText: translations.newPassword,
                          prefixIcon: const Icon(FluentIcons.lock_shield_24_regular),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Wajib diisi';
                          if (val.length < 6) return translations.passwordTooShort;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          labelText: translations.confirmNewPassword,
                          prefixIcon: const Icon(FluentIcons.lock_shield_24_regular),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Wajib diisi';
                          if (val != newPasswordController.text) {
                            return translations.newPasswordNotMatch;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(translations.cancel),
                ),
                FilledButton(
                  onPressed: isSaving ? null : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final router = GoRouter.of(context);

                    try {
                      // Direct password update using Supabase client
                      await ref.read(authControllerProvider).runAuthTask(() async {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: newPasswordController.text.trim()),
                        );
                        await ref.read(authControllerProvider).signOut();
                      });

                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('${translations.changePasswordSuccess} Please login again.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      router.go('/auth'); // Route to auth screen
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('${translations.failed}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSaving) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(isSaving ? translations.saving : translations.save),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete Account PopUp Dialog
  void _showDeleteAccountDialog(AppTranslations translations) {
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            translations.deleteAccount,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.red),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(translations.deleteAccountConfirm),
                const SizedBox(height: 10),
                Text(
                  translations.deleteAccountSubtext,
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    labelText: translations.deleteAccountVerif,
                    hintText: translations.deleteAccountHint,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                    if (val.trim().toUpperCase() != (translations.isIndonesian ? 'HAPUS' : 'DELETE')) {
                      return 'Ketik verifikasi dengan benar';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translations.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                try {
                  // Direct deletion simulation and signout
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translations.deleteAccountSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.go('/auth');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${translations.failed}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(translations.deleteAccount),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationsProvider);
    final activeThemeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(sharedPreferencesProvider);

    // Get Notification Switches from SharedPreferences
    final isNotifVirtualClass = prefs.getBool('notif_virtual_class') ?? true;
    final isNotifChat = prefs.getBool('notif_chat') ?? true;
    final isNotifTransaction = prefs.getBool('notif_transaction') ?? true;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Text(
            translations.settings,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF4B176E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Section App Theme
          _buildSectionHeader(translations.themeSetting),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2336) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    title: translations.themeLight,
                    icon: FluentIcons.weather_sunny_24_regular,
                    activeIcon: FluentIcons.weather_sunny_24_filled,
                    isSelected: activeThemeMode == ThemeMode.light,
                    onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThemeOption(
                    title: translations.themeDark,
                    icon: FluentIcons.weather_moon_24_regular,
                    activeIcon: FluentIcons.weather_moon_24_filled,
                    isSelected: activeThemeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThemeOption(
                    title: translations.themeSystem,
                    icon: FluentIcons.settings_24_regular,
                    activeIcon: FluentIcons.settings_24_filled,
                    isSelected: activeThemeMode == ThemeMode.system,
                    onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // Section Language
          _buildSectionHeader(translations.languageSetting),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.translate_24_regular,
                  color: isDark ? Colors.white : const Color(0xFF4B176E),
                ),
              ),
              title: Text(
                translations.languageSetting,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(translations.languageSettingSub),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    translations.isIndonesian ? 'Bahasa Indonesia' : 'English (US)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(FluentIcons.chevron_right_24_regular),
                ],
              ),
              onTap: () => _showLanguageSelector(context, translations),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // Section Notification Switches
          _buildSectionHeader(translations.notificationSetting),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.video_clip_24_regular,
                      color: isDark ? Colors.white : const Color(0xFF4B176E),
                    ),
                  ),
                  title: Text(
                    translations.notifVirtualClass,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  subtitle: Text(translations.notifVirtualClassSub, style: const TextStyle(fontSize: 12)),
                  value: isNotifVirtualClass,
                  onChanged: (val) {
                    setState(() {
                      prefs.setBool('notif_virtual_class', val);
                    });
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile.adaptive(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.chat_24_regular,
                      color: isDark ? Colors.white : const Color(0xFF4B176E),
                    ),
                  ),
                  title: Text(
                    translations.notifChat,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  subtitle: Text(translations.notifChatSub, style: const TextStyle(fontSize: 12)),
                  value: isNotifChat,
                  onChanged: (val) {
                    setState(() {
                      prefs.setBool('notif_chat', val);
                    });
                  },
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile.adaptive(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.payment_24_regular,
                      color: isDark ? Colors.white : const Color(0xFF4B176E),
                    ),
                  ),
                  title: Text(
                    translations.notifTransaction,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  subtitle: Text(translations.notifTransactionSub, style: const TextStyle(fontSize: 12)),
                  value: isNotifTransaction,
                  onChanged: (val) {
                    setState(() {
                      prefs.setBool('notif_transaction', val);
                    });
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // Section Security
          _buildSectionHeader(translations.securitySetting),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.lock_shield_24_regular,
                      color: isDark ? Colors.white : const Color(0xFF4B176E),
                    ),
                  ),
                  title: Text(
                    translations.changePassword,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(FluentIcons.chevron_right_24_regular),
                  onTap: () => _showChangePasswordDialog(translations),
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28354E) : const Color(0xFFFEF2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FluentIcons.delete_24_regular,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    translations.deleteAccount,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
                  ),
                  trailing: const Icon(FluentIcons.chevron_right_24_regular, color: Colors.red),
                  onTap: () => _showDeleteAccountDialog(translations),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // Section Cache Clearer
          _buildSectionHeader(translations.cacheSetting),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.box_24_regular,
                  color: isDark ? Colors.white : const Color(0xFF4B176E),
                ),
              ),
              title: Text(
                translations.clearCache,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _isLoadingCache
                    ? 'Calculating...'
                    : '${translations.cacheSize}: ${_cacheSizeMb.toStringAsFixed(2)} MB',
              ),
              trailing: Icon(
                FluentIcons.delete_24_regular,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => _clearCache(translations),
            ),
          ).animate().fadeIn(duration: 550.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // Section FAQ Accordion
          _buildSectionHeader(translations.faqSetting),
          Card(
            child: Column(
              children: translations.faqList.map((faq) {
                return Column(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(
                          FluentIcons.question_circle_24_regular,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text(
                          faq['q'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
                            child: Text(
                              faq['a'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (translations.faqList.last != faq)
                      const Divider(height: 1, indent: 56),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 24),

          // About Section
          Card(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    FluentIcons.info_24_filled,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translations.aboutApp,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    translations.appVersion,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 650.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: Color(0xFFFF1377),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
