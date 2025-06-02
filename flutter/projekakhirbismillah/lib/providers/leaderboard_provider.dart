import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardProvider with ChangeNotifier {
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardStats? _stats;
  UserRank? _userRank;
  bool _isLoading = false;
  String? _errorMessage;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  LeaderboardStats? get stats => _stats;
  UserRank? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLeaderboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getLeaderboard();
      print('Leaderboard API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Handle the correct response structure
        if (data['success'] == true && data['data'] is List) {
          // Nested response structure
          _leaderboard = (data['data'] as List)
              .map((json) => LeaderboardEntry.fromJson(json))
              .toList();
          print('Loaded ${_leaderboard.length} leaderboard entries (nested)');
        } else if (data is List) {
          // Direct array response - this is the correct structure
          _leaderboard = (data as List)
              .map((json) => LeaderboardEntry.fromJson(json))
              .toList();
          print('Loaded ${_leaderboard.length} leaderboard entries (direct)');
        } else {
          _errorMessage = 'Invalid leaderboard data format';
          _leaderboard = [];
        }
      } else {
        _errorMessage = response['error'] ?? 'Failed to load leaderboard';
        _leaderboard = [];
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
      _errorMessage = 'Network error: $e';
      _leaderboard = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLeaderboardStats() async {
    try {
      final response = await ApiService.getLeaderboardStats();
      print('Leaderboard Stats Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Handle the correct response structure for stats
        if (data['success'] == true && data['data'] != null) {
          _stats = LeaderboardStats.fromJson(data['data']);
        } else if (data != null) {
          _stats = LeaderboardStats.fromJson(data);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading leaderboard stats: $e');
    }
  }

  Future<void> loadUserRank() async {
    try {
      final response = await ApiService.getUserRank();
      print('User Rank Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Handle the correct response structure for user rank
        if (data['success'] == true && data['data'] != null) {
          _userRank = UserRank.fromJson(data['data']);
        } else if (data != null) {
          _userRank = UserRank.fromJson(data);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user rank: $e');
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadLeaderboard(),
      loadLeaderboardStats(),
      loadUserRank(),
    ]);
  }
}
