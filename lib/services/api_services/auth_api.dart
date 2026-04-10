import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user_model.dart';

class AuthService { 
  static const _storage = FlutterSecureStorage();
  static const _keyUserData = 'user_data';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyId = 'user_id';
  static const _keyUsername = 'username';
  static const _keyRecoveryHash = 'recovery_hash';
  static const _keyUserLogo = 'user_logo';
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  Future<UserModel> authenticate({
    required String mode,
    required String recovery,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'auth',
          'mode': mode,
          'recovery': recovery,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final user = UserModel.fromJson(jsonResponse['user']);
           
          await saveToSecureStorage(user);
          
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
 
  Future<UserModel?> getCurrentUser() async {
    final isLoggedInStr = await _storage.read(key: _keyIsLoggedIn);
    if (isLoggedInStr != 'true') return null;

    final userJson = await _storage.read(key: _keyUserData);
    if (userJson == null) return null;

    try {
      return UserModel.fromJson(json.decode(userJson));
    } catch (e) {
      print('Error decoding secure user: $e');
      return null;
    }
  }
 
  Future<String> getVisitorId() async {
    final user = await getCurrentUser();
    return user?.recoveryHash ?? '';
  }
 
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api.php?action=logout'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      await clearSecureStorage();
    }
  }
 
  Future<bool> isUserLoggedIn() async {
    final status = await _storage.read(key: _keyIsLoggedIn);
    return status == 'true';
  }
 
Future<void> saveToSecureStorage(UserModel user) async { 

  await _storage.write(key: _keyIsLoggedIn, value: 'true'); 
  await _storage.write(key: _keyId, value: user.id?.toString() ?? '');
  await _storage.write(key: _keyUsername, value: user.name ?? '');
  await _storage.write(key: _keyRecoveryHash, value: user.recoveryHash ?? '');
  await _storage.write(key: _keyUserLogo, value: user.userLogo ?? '');
  
  print('User fields saved individually to Secure Storage');
}

  Future<void> clearSecureStorage() async {
    await _storage.delete(key: _keyUserData);
    await _storage.delete(key: _keyIsLoggedIn);
    print(' User data wiped from secure storage');
  }
}