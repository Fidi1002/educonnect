enum AppUserRole { unknown, student, tutor }

extension AppUserRoleX on AppUserRole {
  String get value {
    switch (this) {
      case AppUserRole.unknown:
        return 'unknown';
      case AppUserRole.student:
        return 'student';
      case AppUserRole.tutor:
        return 'tutor';
    }
  }

  static AppUserRole fromValue(String? value) {
    switch (value) {
      case 'student':
        return AppUserRole.student;
      case 'tutor':
        return AppUserRole.tutor;
      default:
        return AppUserRole.unknown;
    }
  }
}
