import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:educonnect/features/discovery/presentation/pages/discovery_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = 'splash';
  static const routePath = '/';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }

      context.goNamed(DiscoveryPage.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
