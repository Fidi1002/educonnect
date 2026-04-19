import 'package:supabase_flutter/supabase_flutter.dart';

final class AuthErrorMapper {
  AuthErrorMapper._();

  static String messageFrom(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'Email atau password tidak sesuai.';
      }
      if (message.contains('email not confirmed')) {
        return 'Email belum terverifikasi. Cek inbox email kamu.';
      }
      if (message.contains('user already registered')) {
        return 'Email sudah terdaftar. Silakan login.';
      }
      if (message.contains('password')) {
        return 'Password tidak memenuhi syarat keamanan.';
      }
      if (message.contains('network') || message.contains('socket')) {
        return 'Koneksi internet bermasalah. Coba lagi.';
      }
      return error.message;
    }

    return 'Terjadi kendala sistem. Coba beberapa saat lagi.';
  }
}
