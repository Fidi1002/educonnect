import 'package:educonnect/app/routes/auth_refresh_notifier.dart';
import 'package:educonnect/features/auth/data/repositories/auth_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/presentation/pages/auth_page.dart';
import 'package:educonnect/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:educonnect/features/home/presentation/pages/settings_page.dart';
import 'package:educonnect/features/auth/presentation/pages/role_onboarding_page.dart';
import 'package:educonnect/features/availability/presentation/pages/tutor_availability_page.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/booking/presentation/pages/student_transaction_history_page.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_ebook_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_ebook_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_learning_journal_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_profile_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_shell_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_study_calendar_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_list_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_shell_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_students_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_study_calendar_page.dart';
import 'package:educonnect/features/notifications/presentation/pages/notifications_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_detail_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_form_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_stats_page.dart';
import 'package:educonnect/features/wallet/presentation/pages/tutor_wallet_page.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier();
  
  ref.listen(authStateProvider, (prev, next) {
    notifier.triggerRefresh();
  });
  
  ref.listen(currentUserProfileProvider, (prev, next) {
    notifier.triggerRefresh();
  });
  
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshNotifier = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AuthPage.routePath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final user = authRepository.currentUser;

      final isAuthRoute = location == AuthPage.routePath;
      final isRoleRoute = location == RoleOnboardingPage.routePath;
      final isStudentRoute = location.startsWith('/student');
      final isTutorRoute = location.startsWith('/tutor');

      if (user == null) {
        return isAuthRoute ? null : AuthPage.routePath;
      }

      final profileAsync = ref.read(currentUserProfileProvider);
      
      // If the profile is loading, wait on the current route
      if (profileAsync.isLoading) {
        return null;
      }

      final profile = profileAsync.valueOrNull;
      final role = profile?.role ?? AppUserRole.unknown;
      
      if (role == AppUserRole.unknown) {
        return isRoleRoute ? null : RoleOnboardingPage.routePath;
      }

      if (role == AppUserRole.student) {
        if (isTutorRoute || isAuthRoute || isRoleRoute) {
          return StudentHomePage.routePath;
        }
        return null;
      }

      if (role == AppUserRole.tutor) {
        if (isStudentRoute || isAuthRoute || isRoleRoute) {
          return TutorHomePage.routePath;
        }
        return null;
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
        path: EditProfilePage.routePath,
        name: EditProfilePage.routeName,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return StudentShellPage(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: [
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
            path: StudentBookingsPage.routePath,
            name: StudentBookingsPage.routeName,
            builder: (context, state) => const StudentBookingsPage(),
          ),
          GoRoute(
            path: StudentLearningJournalPage.routePath,
            name: StudentLearningJournalPage.routeName,
            builder: (context, state) => const StudentLearningJournalPage(),
          ),
          GoRoute(
            path: StudentEbookPage.routePath,
            name: StudentEbookPage.routeName,
            builder: (context, state) => const StudentEbookPage(),
          ),
          GoRoute(
            path: StudentProfilePage.routePath,
            name: StudentProfilePage.routeName,
            builder: (context, state) => const StudentProfilePage(),
          ),
          GoRoute(
            path: StudentTransactionHistoryPage.routePath,
            name: StudentTransactionHistoryPage.routeName,
            builder: (context, state) => const StudentTransactionHistoryPage(),
          ),
          GoRoute(
            path: StudentStudyCalendarPage.routePath,
            name: StudentStudyCalendarPage.routeName,
            builder: (context, state) => const StudentStudyCalendarPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return TutorShellPage(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: TutorHomePage.routePath,
            name: TutorHomePage.routeName,
            builder: (context, state) => const TutorHomePage(),
          ),
          GoRoute(
            path: TutorStudentsPage.routePath,
            name: TutorStudentsPage.routeName,
            builder: (context, state) => const TutorStudentsPage(),
          ),
          GoRoute(
            path: TutorBookingsPage.routePath,
            name: TutorBookingsPage.routeName,
            builder: (context, state) => const TutorBookingsPage(),
          ),
          GoRoute(
            path: TutorProfilePage.routePath,
            name: TutorProfilePage.routeName,
            builder: (context, state) => const TutorProfilePage(),
          ),
          GoRoute(
            path: TutorProfileFormPage.routePath,
            name: TutorProfileFormPage.routeName,
            builder: (context, state) => const TutorProfileFormPage(),
          ),
          GoRoute(
            path: TutorStudyCalendarPage.routePath,
            name: TutorStudyCalendarPage.routeName,
            builder: (context, state) => const TutorStudyCalendarPage(),
          ),
          GoRoute(
            path: TutorAvailabilityPage.routePath,
            name: TutorAvailabilityPage.routeName,
            builder: (context, state) => const TutorAvailabilityPage(),
          ),
          GoRoute(
            path: TutorWalletPage.routePath,
            name: TutorWalletPage.routeName,
            builder: (context, state) => const TutorWalletPage(),
          ),
          GoRoute(
            path: TutorStatsPage.routePath,
            name: TutorStatsPage.routeName,
            builder: (context, state) => const TutorStatsPage(),
          ),
          GoRoute(
            path: '/tutor-ebooks',
            name: TutorEbookPage.routeName,
            builder: (context, state) => const TutorEbookPage(),
          ),
        ],
      ),
      GoRoute(
        path: NotificationsPage.routePath,
        name: NotificationsPage.routeName,
        builder: (context, state) => const NotificationsPage(),
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
    ],
  );
});
