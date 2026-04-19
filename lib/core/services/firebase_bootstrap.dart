import 'package:educonnect/core/services/backend_bootstrap.dart';

class BootstrapResult {
  const BootstrapResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

final class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<BootstrapResult> initialize() async {
    final result = await BackendBootstrap.initialize();
    return BootstrapResult(
      isSuccess: result.isSuccess,
      errorMessage: result.errorMessage,
    );
  }
}
