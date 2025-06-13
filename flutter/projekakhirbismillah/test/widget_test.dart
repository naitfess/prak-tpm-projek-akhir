// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:projekakhirbismillah/providers/auth_provider.dart';

import 'package:projekakhirbismillah/main.dart';

void main() {
  testWidgets('App can be launched', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Basic widget rendering test', (WidgetTester tester) async {
    // Build a simple app with providers for testing
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Hello Testing'),
            ),
          ),
        ),
      ),
    );

    // Verify the text renders
    expect(find.text('Hello Testing'), findsOneWidget);
  });
}
