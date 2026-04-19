import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/features/setup/presentation/pages/setup_required_page.dart';

void main() {
  testWidgets('shows setup instructions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SetupRequiredPage(errorMessage: 'missing supabase env'),
      ),
    );

    expect(find.text('EduConnect Setup'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
