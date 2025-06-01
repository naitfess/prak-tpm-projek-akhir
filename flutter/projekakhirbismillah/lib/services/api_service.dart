import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
  static const String baseUrl = 'http://localhost:3000/api'; // For iOS simulator
  
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('Getting token from storage: $token'); // Debug log
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Adding Authorization header: Bearer ${token.substring(0, 20)}...'); // Debug log
    } else {
      print('No token found for headers'); // Debug log
    }
    
    return headers;
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: await getHeaders(),
      );
      return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password, {String role = 'user'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await getHeaders(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // User endpoints
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Teams endpoints
  static Future<Map<String, dynamic>> getTeams() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teams'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load teams'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createTeam(String name, String? logoUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teams'),
        headers: await getHeaders(),
        body: jsonEncode({
          'name': name,
          'logoUrl': logoUrl,
        }),
      );
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to create team'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Match schedules endpoints
  static Future<Map<String, dynamic>> getMatchSchedules() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/match-schedules'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load matches'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createMatchSchedule(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/match-schedules'),
        headers: await getHeaders(),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to create match'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateMatchSchedule(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/match-schedules/$id'),
        headers: await getHeaders(),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to update match'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // News endpoints
  static Future<Map<String, dynamic>> getNews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/news'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load news'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createNews(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/news'),
        headers: await getHeaders(),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to create news'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Predictions endpoints
  static Future<Map<String, dynamic>> getPredictions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/predictions'),
      headers: await getHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPrediction(int matchScheduleId, int predictedTeamId) async {
    try {
      final token = await getToken();
      print('Token for prediction: $token'); // Debug log
      
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final body = jsonEncode({
        'match_schedule_id': matchScheduleId,
        'predicted_team_id': predictedTeamId,
      });
      
      print('Creating prediction with body: $body'); // Debug log
      print('Headers: $headers'); // Debug log
      
      final response = await http.post(
        Uri.parse('$baseUrl/predictions'),
        headers: headers,
        body: body,
      );
      
      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return errorData;
      }
    } catch (e) {
      print('Exception in createPrediction: $e'); // Debug log
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Leaderboard endpoint
  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard'),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load leaderboard'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
