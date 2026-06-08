// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finalyearproject/main.dart';

void main() {
  setUpAll(() async {
    // Supabase must be initialized before MyApp is pumped,
    // since the app relies on Supabase.instance.client.
    await Supabase.initialize(
      url: 'https://qqazpkwsdtrkvwyvznhj.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxYXpwa3dzZHRya3Z3eXZ6bmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMDkzMzAsImV4cCI6MjA5Mzg4NTMzMH0.GrcOdmcUDpt8if830KYIfsuWvKfOYvRg53NZlGsJhfQ',
    );
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
