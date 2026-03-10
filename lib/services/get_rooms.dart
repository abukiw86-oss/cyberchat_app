// lib/services/room_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rooms_model.dart';
import 'cookie_service.dart';

class RoomService {
  static const String baseUrl = 'https://astufindit.x10.mx/cyberchat';
  
  final CookieService _cookieService = CookieService();

Future<List<RoomModel>> fetchRooms() async {
    try {
      await _cookieService.loadCookies();
      final userData = await _cookieService.getCurrentUser();
      final visitorId = userData['visitor_id'] ?? '';
      
      var uri = Uri.parse('$baseUrl/fetch_rooms.php?visitor_id=$visitorId');

      late http.Response response;
      if (visitorId.isNotEmpty) {
        response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
        );
      } else {
        response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> roomsJson = jsonResponse['rooms'];
          return roomsJson.map((json) => RoomModel.fromJson(json)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load rooms');
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rooms: $e');
      throw Exception('Error fetching rooms: $e');
    }
  }


Future<Map<String, dynamic>> joinRoom({
  required String roomCode,
  required String nickname,
  String? password,
  String roomType = 'public',
}) async {
  try {
    final cookieHeader = await _cookieService.getCookieHeader();
    final userData = await _cookieService.getCurrentUser();
     final visitorId = userData['visitor_id'] ?? '';
    
    final response = await http.post(
      Uri.parse('$baseUrl/room_api.php?action=join'),
      headers: {
        'Content-Type': 'application/json',
        ...cookieHeader,
      },
      body: json.encode({
        'action': 'join',
        'room': roomCode,
        'name': nickname,
        'password': password ?? '',
        'room_type': roomType,
        'visitor_id': visitorId,
      }),
    );
        print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(response.body);
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}'
      };
    }
  } catch (e) {
    print(e);
    return {
      'success': false,
      'message': 'Connection error: $e'
    };
  }
}

Future<Map<String, dynamic>> checkRoomPassword({
  required String roomCode,
  required String password,
  required String nickname,
}) async {
  try {
    final cookieHeader = await _cookieService.getCookieHeader();
    final userData = await _cookieService.getCurrentUser();
     final visitorId = userData['visitor_id'] ?? '';
    
    final response = await http.post(
      Uri.parse('$baseUrl/check_room_password.php'),
      headers: {
        'Content-Type': 'application/json',
        ...cookieHeader,
      },
      body: json.encode({
        'room': roomCode,
        'pass': password,
        'name': nickname,
        'visitor_id': visitorId,
      }),
    );


    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('Error checking password: $e');
    return {
      'success': false,
      'message': 'Connection error: $e'
    };
  }
}
}