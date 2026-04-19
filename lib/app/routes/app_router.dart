import 'package:educonnect/app/routes/auth_refresh_notifier.dart';
import 'package:educonnect/features/auth/data/repositories/auth_repository.dart';
import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/presentation/pages/auth_page.dart';
import 'package:educonnect/features/auth/presentation/pages/role_onboarding_page.dart';
import 'package:educonnect/features/availability/presentation/pages/tutor_availability_page.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_list_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_detail_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_form_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final notifier = AuthRefreshNotifier(authRepository.authStateChanges());
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final refreshNotifier = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AuthPage.routePath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final user = authRepository.currentUser;

      final isAuthRoute = location == AuthPage.routePath;
      final isRoleRoute = location == RoleOnboardingPage.routePath;
      final isStudentRoute = location.startsWith('/student');
      final isTutorRoute = location.startsWith('/tutor');

      if (user == null) {
        return isAuthRoute ? null : AuthPage.routePath;
      }

      var profile = await userRepository.fetchUserProfile(user.uid);
      if (profile == null) {
        await userRepository.upsertFromAuthUser(user);
        profile = await userRepository.fetchUserProfile(user.uid);
      }

      final role = profile?.role ?? AppUserRole.unknown;
      if (role == AppUserRole.unknown) {
        return isRoleRoute ? null : RoleOnboardingPage.routePath;
      }

      if (role == AppUserRole.student) {
        return isStudentRoute ? null : StudentHomePage.routePath;
      }

      if (role == AppUserRole.tutor) {
        return isTutorRoute ? null : TutorHomePage.routePath;
      }

      return AuthPage.routePath;
    },
    routes: [
      GoRoute(
        path: AuthPage.routePath,
        name: AuthPage.routeName,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: RoleOnboardingPage.routePath,
        name: RoleOnboardingPage.routeName,
        builder: (context, state) => const RoleOnboardingPage(),
      ),
      GoRoute(
        path: StudentHomePage.routePath,
        name: StudentHomePage.routeName,
        builder: (context, state) => const StudentHomePage(),
      ),
      GoRoute(
        path: TutorListPage.routePath,
        name: TutorListPage.routeName,
        builder: (context, state) => const TutorListPage(),
      ),
      GoRoute(
        path: TutorDetailPage.routePath,
        name: TutorDetailPage.routeName,
        builder: (context, state) {
          final tutorId = state.pathParameters['tutorId'] ?? '';
          return TutorDetailPage(tutorId: tutorId);
        },
      ),
      GoRoute(
        path: TutorHomePage.routePath,
        name: TutorHomePage.routeName,
        builder: (context, state) => const TutorHomePage(),
      ),
      GoRoute(
        path: StudentBookingsPage.routePath,
        name: StudentBookingsPage.routeName,
        builder: (context, state) => const StudentBookingsPage(),
      ),
      GoRoute(
        path: TutorBookingsPage.routePath,
        name: TutorBookingsPage.routeName,
        builder: (context, state) => const TutorBookingsPage(),
      ),
      GoRoute(
        path: TutorAvailabilityPage.routePath,
        name: TutorAvailabilityPage.routeName,
        builder: (context, state) => const TutorAvailabilityPage(),
      ),
      GoRoute(
        path: InboxPage.routePath,
        name: InboxPage.routeName,
        builder: (context, state) => const InboxPage(),
      ),
      GoRoute(
        path: ChatPage.routePath,
        name: ChatPage.routeName,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return ChatPage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: TutorProfileFormPage.routePath,
        name: TutorProfileFormPage.routeName,
        builder: (context, state) => const TutorProfileFormPage(),
      ),
    ],
  );
});
