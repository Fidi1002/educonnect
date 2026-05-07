import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_ebook_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/student_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShellPage extends StatelessWidget {
  const StudentShellPage({
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
              context.go(StudentHomePage.routePath);
            case 1:
              context.go(StudentBookingsPage.routePath);
            case 2:
              context.go(StudentEbookPage.routePath);
            case 3:
              context.go(StudentProfilePage.routePath);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Kelas'),
          NavigationDestination(
            icon: Icon(Icons.auto_stories),
            label: 'E-Book',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/student/bookings')) {
      return 1;
    }
    if (location.startsWith('/student/learning-journal')) {
      return 1;
    }
    if (location.startsWith('/student/ebooks')) {
      return 2;
    }
    if (location.startsWith('/student/profile')) {
      return 3;
    }
    return 0;
  }
}
