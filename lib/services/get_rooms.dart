// lib/services/room_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rooms_model.dart';
import 'cookie_service.dart';
import 'chache_service.dart'; // Import cache service

class RoomService {
  static const String baseUrl = 'https://astufindit.x10.mx/cyberchat';
  
  final CookieService _cookieService = CookieService();
  final CacheService _cacheService = CacheService(); 

  // Fetch all rooms with caching
Future<List<RoomModel>> fetchRooms({bool forceRefresh = false}) async {
  try {
    await _cookieService.loadCookies();
    final userData = await _cookieService.getCurrentUser();
    final visitorId = userData['visitor_id'] ?? '';
    
    final cacheKey = 'all_rooms_$visitorId';

    print('🌐 Fetching fresh rooms from API');
    var uri = Uri.parse('$baseUrl/fetch_rooms.php?action=get_user_rooms&visitor_id=$visitorId');

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
    print('🔍 Response status: ${response.statusCode}');
    print('🔍 Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      if (response.body.trim().startsWith('{')) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> roomsJson = jsonResponse['rooms'] ?? jsonResponse['user_rooms'] ?? [];
          final rooms = roomsJson.map((json) => RoomModel.fromJson(json)).toList();
          
          await _cacheService.cacheRooms(rooms, key: cacheKey);
          
          for (var room in rooms) {
            if (room.haslogo) {
              _cacheService.precacheImage('${baseUrl}/${room.logoPath}');
            }
          }
          
          return rooms;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load rooms');
        }
      } else {
        print('❌ Response is not JSON. First 200 chars: ${response.body}');
        throw Exception('Invalid response format from server');
      }
    } else {
      throw Exception('Failed to load rooms: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching rooms: $e');

    final userData = await _cookieService.getCurrentUser();
    final visitorId = userData['visitor_id'] ?? '';
    final cacheKey = 'all_rooms_$visitorId';
    final cachedRooms = _cacheService.getCachedRooms(key: cacheKey);
    
    if (cachedRooms != null) {
      print('📦 Returning cached rooms due to error');
      return cachedRooms;
    }
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
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // If successful, invalidate rooms cache
        if (result['success'] == true) {
          await _cacheService.clearRoomsCache();
          // Also clear user created rooms cache
          // await _cacheService.clearRoomsCache(key: 'user_created_$visitorId');
        }
        
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

  // Check room password (no caching needed)
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
        final result = json.decode(response.body);
        
        // If password correct, invalidate rooms cache
        if (result['success'] == true) {
          await _cacheService.clearRoomsCache();
        }
        
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

  // Fetch user created rooms with caching
  Future<List<RoomModel>> fetchUsercreatedRooms({bool forceRefresh = false}) async {
    try {
      await _cookieService.loadCookies();
      final userData = await _cookieService.getCurrentUser();
      final visitorId = userData['visitor_id'] ?? '';
      
      final cacheKey = 'user_created_$visitorId';
      
      // Check cache first
      if (!forceRefresh) {
        final cachedRooms = _cacheService.getCachedRooms(key: cacheKey);
        if (cachedRooms != null) {
          print('📦 Using cached user created rooms');
          return cachedRooms;
        }
      }

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
          
          // Cache the rooms
          await _cacheService.cacheRooms(rooms, key: cacheKey);
          
          return rooms;
        } else {
          return []; // Return empty list on API error
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user created rooms: $e');
      
      // Try to return cached data on error
      final userData = await _cookieService.getCurrentUser();
      final visitorId = userData['visitor_id'] ?? '';
      final cacheKey = 'user_created_$visitorId';
      final cachedRooms = _cacheService.getCachedRooms(key: cacheKey);
      
      if (cachedRooms != null) {
        print('📦 Returning cached user created rooms due to error');
        return cachedRooms;
      }
      
      return []; // Return empty list on error
    }
  }

  // Add method to manually refresh all room data
  Future<void> refreshAllRoomData() async {
    await _cacheService.clearRoomsCache();
    await fetchRooms(forceRefresh: true);
    
    final userData = await _cookieService.getCurrentUser();
    final visitorId = userData['visitor_id'] ?? '';
    if (visitorId.isNotEmpty) {
      await fetchUsercreatedRooms(forceRefresh: true);
    }
  }
}