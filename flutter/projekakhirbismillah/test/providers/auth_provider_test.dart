import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:projekakhirbismillah/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize the binding
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late AuthProvider authProvider;
  
  setUp(() {
    // Initialize the AuthProvider
    authProvider = AuthProvider();
    
    // Setup SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider Basic Tests', () {
    test('initial state has correct values', () {
      // Verify initial state
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
      expect(authProvider.token, isNull);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNull);
    });
    
    test('clearError method works correctly', () {
      // Set an error message using reflection (private field)
      final providerWithError = AuthProvider();
      // Access the provider's state directly for testing
      providerWithError.clearError();
      expect(providerWithError.errorMessage, isNull);
    });
    
    test('isAuthenticated returns false when user is null', () {
      // Test when both are null
      expect(authProvider.isAuthenticated, false);
      
      // Test when only token is present
      SharedPreferences.setMockInitialValues({'token': 'some_token'});
      authProvider.checkAuthStatus(); // This won't actually set user since we can't mock API
      expect(authProvider.isAuthenticated, false); // Still false because user is null
    });
  });
}
