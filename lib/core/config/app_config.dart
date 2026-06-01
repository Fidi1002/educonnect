final class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vkhmleulohwavtdvkwdb.supabase.co',
  );
  
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_52V0XsvvtcYYr_XYaKrm8A_Ya0gzmhk',
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

