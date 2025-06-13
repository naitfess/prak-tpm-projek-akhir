import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  String? get errorMessage => _errorMessage;

  // Safe substring method to avoid range errors
  String _safeSubstring(String text, int start, int end) {
    if (text.length <= start) return text;
    if (text.length < end) return text.substring(start);
    return text.substring(start, end);
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      print('Checking auth status, token: ${_safeSubstring(_token!, 0, 20)}...');

      try {
        // Set token ke ApiService jika perlu
        // ApiService.setToken(_token!); // Sudah tidak perlu jika getHeaders sudah benar
        final response = await ApiService.getUserProfile();
        print('getUserProfile response: $response');
        if (response['success'] == true && response['data'] != null) {
          _user = User.fromJson(response['data']);
          notifyListeners();
        } else if (response['error'] == 'Failed to get profile') {
          // Hanya logout jika benar-benar unauthorized
          await logout();
        } else {
          print('Profile fetch failed but not unauthorized, keeping user.');
        }
      } catch (e) {
        print('Auth check error: $e');
        // Jangan langsung logout, bisa jadi hanya error jaringan
      }
    } else {
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(username, password);
      print('Auth provider received response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // Double save token sebagai backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('backup_token', _token!);

        print('Token saved in auth provider: ${_token!.substring(0, 20)}...');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Login failed';
        print('Login failed in auth provider: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String password,
      {String role = 'user'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiService.register(username, password, role: role);

      if (response['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Registration failed';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Register error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout error: $e');
    }

    _user = null;
    _token = null;
    _errorMessage = null;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
