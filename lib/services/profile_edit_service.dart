// lib/services/user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cyberchat/models/user_model.dart';
import 'package:cyberchat/services/cookie_service.dart';

class UserService {
  static const String baseUrl = 'https://astufindit.x10.mx/cyberchat';
  final CookieService _cookieService = CookieService();

  // Get current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=get_user_profile'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
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

  // Check session (kept for backward compatibility)
  Future<UserModel> checkSession() async {
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
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return UserModel.fromJson(jsonResponse['user']);
        }
      }
      return UserModel.guest();
    } catch (e) {
      print('Error checking session: $e');
      return UserModel.guest();
    }
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final userData = await _cookieService.getCurrentUser();
      final visitorId = userData['visitor_id'] ?? '';
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api.php?action=upload_profile_image'),
      );
      
      // Add headers
      request.headers.addAll({
        ...cookieHeader,
      });
      
      // Add visitor_id as field
      request.fields['visitor_id'] = visitorId;
      
      // Prepare file
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      
      // Determine content type based on file extension
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
      
      // Send request
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

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String bio,
    String? recoveryPhrase,
    String? userLogo,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final userData = await _cookieService.getCurrentUser();
      final visitorId = userData['visitor_id'] ?? '';
      
      // Validate inputs
      if (name.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Name cannot be empty',
        };
      }
      
      // Prepare request body
      Map<String, dynamic> requestBody = {
        'action': 'update_profile',
        'visitor_id': visitorId,
        'name': name.trim(),
        'bio': bio.trim(),
      };
      
      // Only include recovery phrase if provided and not empty
      if (recoveryPhrase != null && recoveryPhrase.isNotEmpty) {
        // Validate recovery phrase format
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(recoveryPhrase)) {
          return {
            'success': false,
            'message': 'Recovery phrase can only contain letters, numbers, hyphens, and underscores',
          };
        }
        requestBody['recovery_phrase'] = recoveryPhrase;
      }
      
      // Include user logo if provided
      if (userLogo != null && userLogo.isNotEmpty) {
        requestBody['user_logo'] = userLogo;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=update_profile'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode(requestBody),
      );
        print(response.body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Update cookies if recovery phrase changed
        if (jsonResponse['success'] == true && jsonResponse['user'] != null) {
          // Update local cookies with new data if needed
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

  // Update profile with image upload in one call
  Future<Map<String, dynamic>> updateProfileWithImage({
    required String name,
    required String bio,
    File? imageFile,
    String? recoveryPhrase,
  }) async {
    try {
      // First upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        final uploadResult = await uploadProfileImage(imageFile);
        if (uploadResult['success'] == true) {
          imageUrl = uploadResult['image_url'];
        } else {
          return uploadResult; // Return upload error
        }
      }
      
      // Then update profile
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

  // Get user profile by ID (for viewing other users)
  Future<UserModel?> getUserProfileById(String userId) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=get_user_profile&visitor_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
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

  // Delete profile image
  Future<bool> deleteProfileImage() async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final userData = await _cookieService.getCurrentUser();
      final visitorId = userData['visitor_id'] ?? '';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?action=delete_profile_image'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
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

  // Helper method to update local user data
  Future<void> _updateLocalUserData(Map<String, dynamic> userData) async {
    try {
      // Update cookies if needed
      if (userData['recovery_hash'] != null) {
        // You might want to update stored cookies here
        // This depends on your cookie service implementation
      }
    } catch (e) {
      print('Error updating local user data: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api.php?action=get_user_profile'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
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