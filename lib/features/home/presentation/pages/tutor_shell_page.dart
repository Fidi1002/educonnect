import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_students_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TutorShellPage extends StatelessWidget {
  const TutorShellPage({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  final Widget child;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _indexFromLocation(currentLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(TutorHomePage.routePath);
            case 1:
              context.go(TutorBookingsPage.routePath);
            case 2:
              context.go(TutorStudentsPage.routePath);
            case 3:
              context.go(TutorProfileFormPage.routePath);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Booking'),
          NavigationDestination(icon: Icon(Icons.groups_2), label: 'Murid'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/tutor/bookings') ||
        location.startsWith('/tutor/study-calendar')) {
      return 1;
    }
    if (location.startsWith('/tutor/students')) {
      return 2;
    }
    if (location.startsWith('/tutor/profile') ||
        location.startsWith('/tutor/availability')) {
      return 3;
    }
    return 0;
  }
}
