// lib/services/user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cyberchat/models/user_model.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_api.dart';

class UserService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  final AuthService _authService = AuthService();

Future<UserModel> getCurrentUserProfile( {required String visitorid}) async {
    try {  
        Map<String, dynamic> visitorId = {
        'visitor_id': visitorid,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=get_user_profile'),
        headers: {
          'Content-Type': 'application/json', 
        },
        
        body:json.encode(visitorId)
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return UserModel.fromJson(jsonResponse['user']);
        }
      }
      return UserModel.guest();
    } catch (e) {
      print('Error getting current user: $e');
      return UserModel.guest();
    }
  }

Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try { 
     final visitorId = await _authService.getVisitorId(); 
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api.php?action=upload_profile_image'),
      ); 
       
      request.fields['visitor_id'] = visitorId;
       
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
       
      var contentType = 'image/jpeg';
      if (imageFile.path.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imageFile.path.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (imageFile.path.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }
      
      var multipartFile = http.MultipartFile(
        'profile_image',
        stream,
        length,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType.parse(contentType),
      );
      
      request.files.add(multipartFile);
       
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error uploading image: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
 
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String bio,
    String? recoveryPhrase,
    String? userLogo,
  }) async {
    try { 
      final visitorId = await _authService.getVisitorId(); 
       
      if (name.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Name cannot be empty',
        };
      }
       
      Map<String, dynamic> requestBody = {
        'action': 'update_profile',
        'visitor_id': visitorId,
        'name': name.trim(),
        'bio': bio.trim(),
      };
       
      if (recoveryPhrase != null && recoveryPhrase.isNotEmpty) { 
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(recoveryPhrase)) {
          return {
            'success': false,
            'message': 'Recovery phrase can only contain letters, numbers, hyphens, and underscores',
          };
        }
        requestBody['recovery_phrase'] = recoveryPhrase;
      }
       
      if (userLogo != null && userLogo.isNotEmpty) {
        requestBody['user_logo'] = userLogo;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=update_profile'),
        headers: {
          'Content-Type': 'application/json', 
        },
        body: json.encode(requestBody),
      );
        print(response.body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
         
        if (jsonResponse['success'] == true && jsonResponse['user'] != null) { 
          await _updateLocalUserData(jsonResponse['user']);
        }
        
        return jsonResponse;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
 
  Future<Map<String, dynamic>> updateProfileWithImage({
    required String name,
    required String bio,
    File? imageFile,
    String? recoveryPhrase,
  }) async {
    try { 
      String? imageUrl;
      if (imageFile != null) {
        final uploadResult = await uploadProfileImage(imageFile);
        if (uploadResult['success'] == true) {
          imageUrl = uploadResult['image_url'];
        } else {
          return uploadResult;  
        }
      } 
      return await updateUserProfile(
        name: name,
        bio: bio,
        recoveryPhrase: recoveryPhrase,
        userLogo: imageUrl,
      );
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  } 

  Future<UserModel?> getUserProfileById(String userId) async {
    try { 
      
      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=get_user_profile&visitor_id=$userId'),
        headers: {
          'Content-Type': 'application/json', 
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return UserModel.fromJson(jsonResponse['user']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
 
  Future<bool> deleteProfileImage() async {
    try { 
     final visitorId = await _authService.getVisitorId(); 
      
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=delete_profile_image'),
        headers: {
          'Content-Type': 'application/json', 
        },
        body: json.encode({
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }
 
  Future<void> _updateLocalUserData(Map<String, dynamic> userData) async {
    try { 
      if (userData['recovery_hash'] != null) { 
      }
    } catch (e) {
      print('Error updating local user data: $e');
    }
  }
 
  Future<Map<String, dynamic>> getUserStats() async {
    try { 
      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=get_user_profile'),
        headers: {
          'Content-Type': 'application/json', 
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['user']['stats'] != null) {
          return jsonResponse['user']['stats'];
        }
      }
      return {
        'rooms_created': 0,
        'messages_sent': 0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'rooms_created': 0,
        'messages_sent': 0,
      };
    }
  }
}