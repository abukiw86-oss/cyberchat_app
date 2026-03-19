// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'cookie_service.dart';

class AuthService {
  static const String baseUrl = 'https://astufindit.x10.mx/cyberchat';
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
          final user = UserModel.fromJson(jsonResponse['user']);
          
          await user.saveToPrefs();
          
          return user;
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

  Future<UserModel?> checkSession({bool forceApiCheck = false}) async {
    try {
      if (!forceApiCheck) {
        final cachedUser = await UserModel.loadFromPrefs();
        if (cachedUser != null) {
          print(' Using cached user from SharedPreferences');
          return cachedUser;
        }
      }

      print('Checking session with API');
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
          final user = UserModel.fromJson(jsonResponse['user']);
          await user.saveToPrefs();
          return user;
        }
      }
      await UserModel.clearFromPrefs();
      return null;
      
    } catch (e) {
      print('Session check error: $e');
      return await UserModel.loadFromPrefs();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    return await UserModel.loadFromPrefs();
  }

  Future<String> getVisitorId() async {
    final user = await UserModel.loadFromPrefs();
    return user?.recoveryHash ?? '';
  }

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
      await UserModel.clearFromPrefs();
    }
  }

  Future<bool> isUserLoggedIn() async {
    UserModel user = UserModel();
    return await user.isLoggedIn();
  }
}