import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projekakhirbismillah/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Simple UI test - verify login screen elements', (WidgetTester tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle();

    // Verify login screen elements
    expect(find.text('Football Prediction'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
    
    // Check if the form fields are present
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    
    // Verify the login button is present
    expect(find.widgetWithText(ElevatedButton, 'LOGIN'), findsOneWidget);
    
    // Verify the register link is present
    expect(find.text("Don't have an account? Register here"), findsOneWidget);
    
    // Test basic interaction - tap register link
    await tester.tap(find.text("Don't have an account? Register here"));
    await tester.pumpAndSettle();
    
    // Verify we navigate to register screen
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join our community!'), findsOneWidget);
  });
}
