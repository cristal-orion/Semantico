import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user_models.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  // Reuse base URL from ApiService
  static const String baseUrl = ApiService.baseUrl;

  /// Register a new user
  Future<AuthResponse> register(
      String username, String? email, String password) async {
    // Build request body - only include email if it's not empty
    final Map<String, dynamic> body = {
      'username': username,
      'password': password,
    };

    // Only add email if it's non-null and non-empty
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Errore durante la registrazione');
    }
  }

  /// Login with username/email and password
  Future<AuthResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Credenziali non valide');
    }
  }

  /// Get current user info
  Future<User> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw AuthException('Sessione scaduta');
    } else {
      throw Exception('Errore server: ${response.statusCode}');
    }
  }

  /// Logout (API call for consistency, actual logout is client-side)
  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignore errors on logout
      print('Logout error: $e');
    }
  }

  /// Upload user avatar
  Future<User> uploadAvatar(String token, String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/users/avatar'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore caricamento avatar');
    }
  }

  /// Delete user avatar
  Future<User> deleteAvatar(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/avatar'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore eliminazione avatar');
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/auth/account'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Errore eliminazione account');
    }
  }
}
