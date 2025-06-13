import 'package:projekakhirbismillah/services/api_service.dart';

class MockApiService {
  static final Map<String, dynamic> _userResponse = {
    'success': true,
    'data': {
      'id': 1,
      'username': 'testuser',
      'role': 'user',
      'poin': 100
    }
  };

  static final Map<String, dynamic> _loginResponse = {
    'success': true,
    'data': {
      'token': 'mock_token',
      'user': {
        'id': 1,
        'username': 'testuser',
        'role': 'user',
        'poin': 100
      }
    }
  };

  static final Map<String, dynamic> _matchesResponse = {
    'success': true,
    'data': [
      {
        'id': 1,
        'team1': {
          'id': 1,
          'name': 'Team 1',
          'logoUrl': 'https://example.com/logo1.png'
        },
        'team2': {
          'id': 2,
          'name': 'Team 2',
          'logoUrl': 'https://example.com/logo2.png'
        },
        'date': '2023-06-01',
        'time': '15:00',
        'status': 'Belum Dimainkan',
        'is_finished': false,
        'winner': null,
        'skor1': null,
        'skor2': null
      }
    ]
  };

  static final Map<String, dynamic> _teamsResponse = {
    'success': true,
    'data': [
      {
        'id': 1,
        'name': 'Team 1',
        'logoUrl': 'https://example.com/logo1.png'
      },
      {
        'id': 2,
        'name': 'Team 2',
        'logoUrl': 'https://example.com/logo2.png'
      }
    ]
  };

  // Setup method to replace ApiService with mock responses
  static void setupMockResponses() {
    // Ideally we'd use method injection or a DI framework, but for testing
    // this is a simpler approach
  }
}
