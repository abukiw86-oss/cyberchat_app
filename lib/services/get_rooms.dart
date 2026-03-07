// lib/services/room_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rooms_model.dart';

class RoomService {
  static const String baseUrl = 'https://astufindit.x10.mx/cyberchat';
  
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
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Error fetching rooms: $e');
    }
  }

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

  Future<List<RoomModel>> fetchPublicRooms() async {
    final rooms = await fetchRooms();
    return rooms.where((room) => room.isPublic).toList();
  }
 
  Future<List<RoomModel>> fetchPrivateRooms() async {
    final rooms = await fetchRooms();
    return rooms.where((room) => !room.isPublic).toList();
  }

}