import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class PredictionProvider with ChangeNotifier {
  List<Prediction> _predictions = [];
  List<User> _leaderboard = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Prediction> get predictions => _predictions;
  List<User> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPredictions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getPredictions();
      if (response['success'] == true && response['data'] is List) {
        _predictions = (response['data'] as List)
            .map((json) => Prediction.fromJson(json))
            .toList();
      } else {
        _predictions = [];
        _errorMessage = response['message'] ?? 'Failed to load predictions';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLeaderboard() async {
    try {
      final response = await ApiService.getLeaderboard();
      if (response['success']) {
        _leaderboard = (response['data'] as List)
            .map((json) => User.fromJson(json))
            .toList();
        _leaderboard.sort((a, b) => b.poin.compareTo(a.poin));
        notifyListeners();
      } else {
        _errorMessage = response['error'] ?? 'Failed to load leaderboard';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error loading leaderboard: $e');
    }
  }

  Future<bool> createPrediction(int matchScheduleId, int predictedTeamId) async {
    try {
      final response = await ApiService.createPrediction(matchScheduleId, predictedTeamId);
      print('Create prediction response: $response'); // Debug log
      
      if (response['success'] == true) {
        await loadPredictions(); // Reload predictions setelah berhasil
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create prediction';
        print('Error creating prediction: $_errorMessage'); // Debug log
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Exception creating prediction: $e'); // Debug log
      notifyListeners();
      return false;
    }
  }

  bool hasPredictedMatch(int matchId) {
    return _predictions.any((p) => p.matchScheduleId == matchId);
  }

  Prediction? getPredictionForMatch(int matchId) {
    try {
      return _predictions.firstWhere((p) => p.matchScheduleId == matchId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
