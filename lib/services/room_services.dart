// lib/services/room_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rooms_model.dart';

class RoomService {
  static const String baseUrl = 'https://cyberchat.unaux.com';
  
  Future<List<RoomModel>> fetchRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fetch_rooms.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          List<dynamic> roomsJson = jsonResponse['rooms'];
          return roomsJson.map((json) => RoomModel.fromJson(json)).toList();
        } else {
          _getMockRooms();
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print(e.toString().substring(0,130));
      throw Exception('Error fetching rooms: $e');
      
      
    }
  }

  // Optional: Fetch single room by code
  Future<RoomModel?> fetchRoomByCode(String code) async {
    try {
      final rooms = await fetchRooms();
      return rooms.firstWhere(
        (room) => room.code.toLowerCase() == code.toLowerCase(),
        orElse: () => throw Exception('Room not found'),
      );
    } catch (e) {
      throw Exception('Error finding room: $e');
    }
  }

  // Optional: Get public rooms only
  Future<List<RoomModel>> fetchPublicRooms() async {
    final rooms = await fetchRooms();
    return rooms.where((room) => room.isPublic).toList();
  }

  // Optional: Get private rooms only
  Future<List<RoomModel>> fetchPrivateRooms() async {
    final rooms = await fetchRooms();
    return rooms.where((room) => !room.isPublic).toList();
  }
  List<RoomModel> _getMockRooms() {
    return [
      RoomModel(
        code: 'Welcome',
        participants: 10,
        lastActive: DateTime.now().toIso8601String(),
        nickname: 'Abuki',
        status: 'public',
        logoPath: '',
        userLimits: 100,
      ),
      RoomModel(
        code: 'General',
        participants: 5,
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        nickname: 'System',
        status: 'public',
        logoPath: '',
        userLimits: 50,
      ),
      RoomModel(
        code: 'TechTalk',
        participants: 3,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        nickname: 'Admin',
        status: 'private',
        logoPath: '',
        userLimits: 20,
      ),
    ];
  }
}