import 'dart:convert'; 
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; 
import 'rooms_cache_service.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {

  static String get baseUrl   => dotenv.env['BASE_URL'] ?? ''; 
  final RoomCacheService _cacheService = RoomCacheService();

  
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
         
        
        if (jsonResponse['success'] == true) {
          final user = UserModel.fromJson(jsonResponse['user']);
          print(user);
          await user.saveToPrefs();
          if (jsonResponse['user_logo'] != null){
            final userLogo = jsonResponse['user_logo'];
            _cacheService.precacheImage('$baseUrl/$userLogo');
          }
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

  Future<UserModel?> _checkSession({bool forceApiCheck = false}) async {
    try {
      if (!forceApiCheck) {
        final cachedUser = await UserModel.loadFromPrefs();
        if (cachedUser != null) {
          print(' Using cached user from SharedPreferences');
          return cachedUser;
        }
      }

      print('Checking session with API');
      final visitorId = getVisitorId();

      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=check_session&id=$visitorId'),
        headers: {
          'Content-Type': 'application/json', 
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final user = UserModel.fromJson(jsonResponse['user']);
          await user.saveToPrefs();
          print(jsonResponse['user']['user_logo']);
          print(user.userLogo); 
          return user;
        }
      }

      await UserModel.clearFromPrefs();
      bool isLoggedIn = await isUserLoggedIn();
      if(isLoggedIn){
      logout();
      }
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
      
      await http.post(
        Uri.parse('$baseUrl/api.php?action=logout'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await UserModel.clearFromPrefs();
    }
  }

  Future<bool> isUserLoggedIn() async {
    UserModel user = UserModel();
    return await user.isLoggedIn();
  }
}