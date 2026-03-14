import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/message_model.dart';
import 'cookie_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class RoomApiService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  final CookieService _cookieService = CookieService();

  Future<List<MessageModel>> getMessages(String roomCode, {int lastId = 0}) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=get_messages'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'get_messages',
          'room': roomCode,
          'last_id': lastId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);
        if (jsonResponse['success']) {
          List<dynamic> messagesJson = jsonResponse['messages'];
          return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting messages: $e');
    }
  }

  Future<bool> sendMessage({
    required String roomCode,
    required String message,
    required String nickname,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=send_message'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'send_message',
          'room': roomCode,
          'message': message,
          'name': nickname,
          'visitor_id': visitorId,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getParticipants(String roomCode) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=get_participants'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'get_participants',
          'room': roomCode,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          List<dynamic> participants = jsonResponse['participants'];
          return participants.cast<Map<String, dynamic>>();
        } else {
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Error getting participants: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBannedUsers(String roomCode) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=get_banned_users'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'get_banned_users',
          'room': roomCode,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          List<dynamic> banned = jsonResponse['banned_users'];
          return banned.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error getting banned users: $e');
      return [];
    }
  }

  Future<bool> removeUser({
    required String roomCode,
    required String userId,
    required String userName,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=remove_user'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'remove_user',
          'room': roomCode,
          'user_id': userId,
          'user_name': userName,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error removing user: $e');
      return false;
    }
  }

  Future<bool> unbanUser({
    required String roomCode,
    required String userId,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=unban_user'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'unban_user',
          'room': roomCode,
          'user_id': userId,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error unbanning user: $e');
      return false;
    }
  }

  Future<bool> makeOwner({
    required String roomCode,
    required String newOwnerId,
    required String newOwnerName,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=make_owner'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'make_owner',
          'room': roomCode,
          'new_owner_id': newOwnerId,
          'new_owner_name': newOwnerName,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error making owner: $e');
      return false;
    }
  }

  Future<bool> leaveRoom(String roomCode) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=leave_room'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'leave_room',
          'room': roomCode,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error leaving room: $e');
      return false;
    }
  }

  Future<bool> updateRoomLimit({
    required String roomCode,
    required int limit,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=update_room_limit'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'update_room_limit',
          'room': roomCode,
          'limit': limit,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error updating room limit: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getRoomInfo(String roomCode) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=get_room_info'),
        headers: {
          'Content-Type': 'application/json',
          ...cookieHeader,
        },
        body: json.encode({
          'action': 'get_room_info',
          'room': roomCode,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          return jsonResponse['room'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting room info: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadFiles({
    required String roomCode,
    required String nickname,
    required List<File> files,
  }) async {
    try {
      final cookieHeader = await _cookieService.getCookieHeader();
      final visitorId = await _getVisitorId();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload.php'),
      );
      
      // Add headers
      request.headers.addAll(cookieHeader);
      
      // Add fields
      request.fields['room'] = roomCode;
      request.fields['name'] = nickname;
      request.fields['visitor_id'] = visitorId;
      
      // Add files
      for (var file in files) {
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        
        var multipartFile = http.MultipartFile(
          'files[]',
          stream,
          length,
          filename: file.path.split('/').last,
          contentType: MediaType('application', 'octet-stream'),
        );
        
        request.files.add(multipartFile);
      }
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        return {'success': false, 'message': 'Upload failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error uploading files: $e'};
    }
  }

  Future<String> _getVisitorId() async {
    await _cookieService.loadCookies();
    final userData = await _cookieService.getCurrentUser();
    return userData['visitor_id'] ?? '';
  }
}