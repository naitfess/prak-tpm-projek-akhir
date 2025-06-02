import 'package:flutter/material.dart';
import '../models/match_schedule.dart';
import '../models/team.dart';
import '../services/api_service.dart';

class MatchProvider with ChangeNotifier {
  List<MatchSchedule> _matches = [];
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchSchedule> get matches => _matches;
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getMatchSchedules();
      print('Raw API Response: $response'); // Debug log

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        // Handle direct data array or nested success response
        if (data['success'] == true && data['data'] is List) {
          // Nested response structure
          try {
            _matches = (data['data'] as List).map((json) {
              print('Processing match: $json'); // Debug log
              return MatchSchedule.fromJson(json);
            }).toList();
            print('Parsed ${_matches.length} matches'); // Debug log
          } catch (parseError) {
            print('Parse error: $parseError'); // Debug log
            _errorMessage = 'Error parsing match data: $parseError';
            _matches = [];
          }
        } else if (data is List) {
          // Direct array response
          try {
            _matches = (data as List).map((json) {
              print('Processing match: $json'); // Debug log
              return MatchSchedule.fromJson(json);
            }).toList();
            print('Parsed ${_matches.length} matches'); // Debug log
          } catch (parseError) {
            print('Parse error: $parseError'); // Debug log
            _errorMessage = 'Error parsing match data: $parseError';
            _matches = [];
          }
        } else {
          print('Invalid data format: $data'); // Debug log
          _errorMessage = 'Invalid data format received';
          _matches = [];
        }
      } else {
        print('Invalid response: $response'); // Debug log
        _errorMessage = response['message'] ?? response['error'] ?? 'Failed to load matches';
        _matches = [];
      }
    } catch (e) {
      print('Network error: $e'); // Debug log
      _errorMessage = 'Network error: $e';
      _matches = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTeams() async {
    try {
      final response = await ApiService.getTeams();
      if (response['success']) {
        _teams = (response['data'] as List)
            .map((json) => Team.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        _errorMessage = response['error'] ?? 'Failed to load teams';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error loading teams: $e');
    }
  }

  Future<bool> createMatch(Map<String, dynamic> matchData) async {
    try {
      final response = await ApiService.createMatchSchedule(matchData);
      if (response['success']) {
        await loadMatches();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to create match';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error creating match: $e');
    }
    return false;
  }

  Future<bool> updateMatch(int id, Map<String, dynamic> matchData) async {
    try {
      final response = await ApiService.updateMatchSchedule(id, matchData);
      if (response['success']) {
        await loadMatches();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to update match';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error updating match: $e');
    }
    return false;
  }

  Future<bool> createTeam(String name, String? logoUrl) async {
    try {
      final response = await ApiService.createTeam(name, logoUrl);
      if (response['success']) {
        await loadTeams();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to create team';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error creating team: $e');
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
