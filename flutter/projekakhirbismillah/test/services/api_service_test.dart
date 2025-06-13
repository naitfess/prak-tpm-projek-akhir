import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:projekakhirbismillah/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate mocks for http.Client
@GenerateMocks([http.Client])
void main() {
  // Initialize the binding
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    // Reset SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiService Tests', () {
    test('getToken returns token from SharedPreferences', () async {
      // Arrange - setup the test
      SharedPreferences.setMockInitialValues({'token': 'mock_token_123'});
      
      // Act - call the method being tested
      final token = await ApiService.getToken();
      
      // Assert - verify the result
      expect(token, 'mock_token_123');
    });

    test('saveToken stores token in SharedPreferences', () async {
      // Arrange
      final testToken = 'new_test_token_456';
      SharedPreferences.setMockInitialValues({});
      
      // Act
      await ApiService.saveToken(testToken);
      final prefs = await SharedPreferences.getInstance();
      
      // Assert
      expect(prefs.getString('token'), testToken);
    });
    
    test('getHeaders includes Authorization header when token exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'token': 'test_auth_token'});
      
      // Act
      final headers = await ApiService.getHeaders();
      
      // Assert
      expect(headers['Authorization'], 'Bearer test_auth_token');
      expect(headers['Content-Type'], 'application/json');
    });
  });
}
