import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_home_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_students_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_page.dart';
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
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomNavItem(
                icon: FluentIcons.home_24_filled,
                isSelected: selectedIndex == 0,
                onTap: () => context.go(TutorHomePage.routePath),
              ),
              _BottomNavItem(
                icon: FluentIcons.calendar_24_filled,
                isSelected: selectedIndex == 1,
                onTap: () => context.go(TutorBookingsPage.routePath),
              ),
              _BottomNavItem(
                icon: FluentIcons.people_24_filled,
                isSelected: selectedIndex == 2,
                onTap: () => context.go(TutorStudentsPage.routePath),
              ),
              _BottomNavItem(
                icon: FluentIcons.person_24_filled,
                isSelected: selectedIndex == 3,
                onTap: () => context.go(TutorProfilePage.routePath),
              ),
            ],
          ),
        ),
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

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B2CBF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF9FA5C0),
        ),
      ),
    );
  }
}
