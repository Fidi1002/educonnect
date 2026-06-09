final class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const supabaseGoogleRedirectUrl = String.fromEnvironment(
    'SUPABASE_GOOGLE_REDIRECT_URL',
    defaultValue: 'io.supabase.educonnect://login-callback/',
  );
  
  static const enableGoogleAuth = bool.fromEnvironment(
    'ENABLE_GOOGLE_AUTH',
    defaultValue: false,
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

