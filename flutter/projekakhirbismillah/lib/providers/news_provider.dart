import 'package:flutter/material.dart';
import '../models/news.dart';
import '../services/api_service.dart';

class NewsProvider with ChangeNotifier {
  List<News> _news = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<News> get news => _news;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadNews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getNews();
      if (response['success']) {
        _news = (response['data'] as List)
            .map((json) => News.fromJson(json))
            .toList();
        _news.sort((a, b) => b.date.compareTo(a.date));
      } else {
        _errorMessage = response['error'] ?? 'Failed to load news';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error loading news: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createNews(Map<String, dynamic> newsData) async {
    try {
      final response = await ApiService.createNews(newsData);
      if (response['success']) {
        await loadNews();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to create news';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error creating news: $e');
    }
    return false;
  }

  Future<bool> updateNews(int id, Map<String, dynamic> newsData) async {
    try {
      final response = await ApiService.updateNews(id, newsData);
      if (response['success']) {
        await loadNews();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to update news';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error updating news: $e');
    }
    return false;
  }

  Future<bool> deleteNews(int id) async {
    try {
      final response = await ApiService.deleteNews(id);
      if (response['success']) {
        await loadNews();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to delete news';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error deleting news: $e');
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
