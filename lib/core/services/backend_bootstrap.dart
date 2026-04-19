import 'package:educonnect/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BootstrapResult {
  const BootstrapResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

final class BackendBootstrap {
  BackendBootstrap._();

  static Future<BootstrapResult> initialize() async {
    if (!AppConfig.hasSupabaseConfig) {
      return const BootstrapResult(
        isSuccess: false,
        errorMessage:
            'SUPABASE_URL / SUPABASE_ANON_KEY belum diisi via --dart-define.',
      );
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      return const BootstrapResult(isSuccess: true);
    } on AuthException catch (error) {
      return BootstrapResult(isSuccess: false, errorMessage: error.message);
    } catch (error) {
      return BootstrapResult(isSuccess: false, errorMessage: error.toString());
    }
  }
}
