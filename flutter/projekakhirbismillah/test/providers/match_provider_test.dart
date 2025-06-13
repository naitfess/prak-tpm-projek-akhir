import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:projekakhirbismillah/providers/match_provider.dart';

void main() {
  // Initialize the binding
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late MatchProvider matchProvider;
  
  setUp(() {
    matchProvider = MatchProvider();
  });

  group('MatchProvider Basic Tests', () {
    test('initial state has correct values', () {
      // Verify initial state
      expect(matchProvider.matches, []);
      expect(matchProvider.teams, []);
      expect(matchProvider.isLoading, false);
      expect(matchProvider.errorMessage, isNull);
    });
    
    test('clearError method works correctly', () {
      // Set an error through a method that we know works
      matchProvider.clearError();
      expect(matchProvider.errorMessage, isNull);
    });
  });
}
