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
      if (response['success'] == true && response['data'] is List) {
        _matches = (response['data'] as List)
            .map((json) => MatchSchedule.fromJson(json))
            .toList();
      } else {
        _matches = [];
        _errorMessage = response['message'] ?? 'Failed to load matches';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
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
