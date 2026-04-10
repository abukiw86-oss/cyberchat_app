// lib/services/room_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/rooms_model.dart';  
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_api.dart'; 

class RoomService {
   static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
   static String get imageurl  => dotenv.env['IMAGE_URL'] ?? '';
  
    
  final AuthService _authService = AuthService();

Future<List<RoomModel>> fetchRooms({bool forceRefresh = false}) async {
  try {
    final visitorId = await _authService.getVisitorId();  
  
    print('🌐 Fetching fresh rooms from API');
    var uri = Uri.parse('$baseUrl/fetch_rooms.php?action=get_user_rooms&visitor_id=$visitorId');
    print(uri);
    late http.Response response;

      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
    print('🔍 Response status: ${response.statusCode}');
    print('🔍 Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      if (response.body.trim().startsWith('{')) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> roomsJson = jsonResponse['rooms'] ?? jsonResponse['user_rooms'] ?? [];
          final rooms = roomsJson.map((json) => RoomModel.fromJson(json)).toList();
           
          
           
          
          return rooms;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load rooms');
        }
      } else {
        print('Response is not JSON ${response.body}');
        throw Exception('Invalid response format from server');
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

     final visitorId = await _authService.getVisitorId(); 
      
      final response = await http.post(
        Uri.parse('$baseUrl/room_api.php?action=join'),
        headers: {
          'Content-Type': 'application/json', 
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
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
         
        
        return result;
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

      final visitorId = await _authService.getVisitorId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/check_room_password.php'),
        headers: {
          'Content-Type': 'application/json', 
        },
        body: json.encode({
          'room': roomCode,
          'pass': password,
          'name': nickname,
          'visitor_id': visitorId,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
         
        
        return result;
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

Future<List<RoomModel>> fetchUsercreatedRooms({bool forceRefresh = false}) async {
    try { 
      final visitorId = await _authService.getVisitorId(); 

      print('🌐 Fetching fresh user created rooms from API');
      var uri = Uri.parse('$baseUrl/fetch_rooms.php?action=get_user_created_room&visitor_id=$visitorId');

      late http.Response response;
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print(response.body);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> roomsJson = jsonResponse['user_rooms'] ?? jsonResponse['rooms'] ?? [];
          final rooms = roomsJson.map((json) => RoomModel.fromJson(json)).toList();
           
          
          return rooms;
        } else {
          return []; 
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user created rooms: $e'); 
      return []; 
    }
  }
}