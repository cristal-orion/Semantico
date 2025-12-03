import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_models.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _token = token;
      try {
        await checkAuth();
      } catch (e) {
        // Error handled in checkAuth
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    if (_token == null) return;
    
    try {
      final user = await _authService.getMe(_token!);
      _user = user;
      notifyListeners();
    } catch (e) {
      if (e is AuthException) {
        _token = null;
        _user = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);
      _token = response.accessToken;
      _user = response.user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String? email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(username, email, password);
      _token = response.accessToken;
      _user = response.user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      await _authService.logout(_token!);
    }
    
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  Future<void> uploadAvatar(String filePath) async {
    if (_token == null) return;
    
    try {
      final updatedUser = await _authService.uploadAvatar(_token!, filePath);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    if (_token == null) return;
    
    try {
      final updatedUser = await _authService.deleteAvatar(_token!);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_token == null) return;
    
    try {
      await _authService.deleteAccount(_token!);
      await logout(); // Logout after deletion
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
