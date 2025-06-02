import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
  static const String baseUrl =
      'https://be-trigger-alungnajib-1061342868557.us-central1.run.app/api'; // For iOS simulator

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print(
          'Getting token from storage: ${token != null ? "${token.substring(0, 20)}..." : "null"}'); // Debug log
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString('token', token);
      print('Token save result: $success');
      print(
          'Token saved in ApiService: ${token.substring(0, 20)}...'); // Debug log

      // Immediate verification
      await Future.delayed(Duration(milliseconds: 100));
      final savedToken = prefs.getString('token');
      print(
          'Immediate verification - token in storage: ${savedToken?.substring(0, 20)}...'); // Debug log

      // Extra verification with different method
      final keys = prefs.getKeys();
      print('All SharedPreferences keys: $keys'); // Debug log
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Adding Authorization header'); // Debug log
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
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: {success: true, message, token, user}
        if (data['success'] == true && data['token'] != null) {
          print(
              'Token received from backend: ${data['token'].substring(0, 20)}...');

          // Save token dengan multiple methods
          await saveToken(data['token']);

          // Alternative save method
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('backup_token', data['token']);
          await prefs.setString('user_token', data['token']);

          print('Token saved with multiple keys');

          return {'success': true, 'data': data};
        } else {
          print('Login failed: no success field or token in response');
          return {'success': false, 'error': 'No token received'};
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password,
      {String role = 'user'}) async {
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

  static Future<Map<String, dynamic>> createTeam(
      String name, String? logoUrl) async {
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
        Uri.parse('$baseUrl/matches'), // Changed from match-schedules to matches
        headers: await getHeaders(),
      );

      print('Match API Response Status: ${response.statusCode}');
      print('Match API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load matches'};
      }
    } catch (e) {
      print('Error in getMatchSchedules: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createMatchSchedule(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/matches'), // Changed endpoint
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

  static Future<Map<String, dynamic>> updateMatchSchedule(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/matches/$id'), // Changed endpoint
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

  // Add finish match endpoint
  static Future<Map<String, dynamic>> finishMatch(int matchId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/matches/$matchId/finish'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to finish match'};
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

  static Future<Map<String, dynamic>> createNews(
      Map<String, dynamic> data) async {
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

  static Future<Map<String, dynamic>> updateNews(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/news/$id'),
        headers: await getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to update news'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteNews(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/news/$id'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to delete news'};
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

  static Future<Map<String, dynamic>> createPrediction(
      int matchScheduleId, int predictedTeamId) async {
    try {
      final token = await getToken();
      print(
          'Creating prediction with token: ${token?.substring(0, 20)}...'); // Debug log

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {
        'match_schedule_id': matchScheduleId,
        'predicted_team_id': predictedTeamId,
      };

      print('Prediction request:');
      print('URL: $baseUrl/predictions');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/predictions'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Prediction response:');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Session expired, please login again');
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Prediction error: $e');
      rethrow;
    }
  }

  // Leaderboard endpoints
  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard'),
        headers: await getHeaders(),
      );

      print('Leaderboard API Response Status: ${response.statusCode}');
      print('Leaderboard API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load leaderboard'};
      }
    } catch (e) {
      print('Error in getLeaderboard: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserRank() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/my-rank'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load user rank'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/stats'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to load leaderboard stats'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
