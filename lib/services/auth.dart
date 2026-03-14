// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'cookie_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AuthService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  final CookieService _cookieService = CookieService();

  Future<UserModel> authenticate({
    required String mode,
    required String recovery,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=auth'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'auth',
          'mode': mode,
          'recovery': recovery,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        _cookieService.saveCookies(response.headers);
        
        if (jsonResponse['success'] == true) {
          return UserModel.fromJson(jsonResponse['user']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Authentication failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<UserModel?> checkSession() async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=check_session'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          return UserModel.fromJson(jsonResponse['user']);
        }
      }
      
      return null;
    } catch (e) {
      print('Session check error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      await http.post(
        Uri.parse('$baseUrl/api.php?action=logout'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
      );
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _cookieService.clearCookies();
    }
  }
}