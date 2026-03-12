// lib/services/cache_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/user_model.dart';
import '../models/rooms_model.dart';
import '../models/message_model.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Box names
  static const String userBoxName = 'userBox';
  static const String roomsBoxName = 'roomsBox';
  static const String messagesBoxName = 'messagesBox';
  static const String imagesBoxName = 'imagesBox';
  static const String timestampsBoxName = 'timestampsBox';
  
  // Cache durations
  static const Duration roomsCacheDuration = Duration(minutes: 5);
  static const Duration messagesCacheDuration = Duration(minutes: 2);
  static const Duration userCacheDuration = Duration(hours: 1);

  // Get boxes
  Box<UserModel> get _userBox => Hive.box<UserModel>(userBoxName);
  Box<List> get _roomsBox => Hive.box<List>(roomsBoxName);
  Box<Map> get _messagesBox => Hive.box<Map>(messagesBoxName);
  Box<String> get _imagesBox => Hive.box<String>(imagesBoxName);
  Box<DateTime> get _timestampsBox => Hive.box<DateTime>(timestampsBoxName);

  // ========== USER CACHING ==========
  
  Future<void> cacheUser(UserModel user) async {
    await _userBox.put('currentUser', user);
    await _timestampsBox.put('userTimestamp', DateTime.now());
  }

  UserModel? getCachedUser() {
    final timestamp = _timestampsBox.get('userTimestamp');
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < userCacheDuration) {
      return _userBox.get('currentUser');
    }
    return null;
  }

  Future<void> clearUserCache() async {
    await _userBox.delete('currentUser');
    await _timestampsBox.delete('userTimestamp');
  }

  // ========== ROOMS CACHING ==========

Future<void> cacheRooms(List<RoomModel> rooms, {String key = 'all'}) async {
  try {
    // Convert to Map for storage
    final roomsMap = rooms.map((r) => r.toJson()).toList();
    await _roomsBox.put('rooms_$key', roomsMap);
    await _timestampsBox.put('roomsTimestamp_$key', DateTime.now());
    print('✅ Cached ${rooms.length} rooms with key: $key');
  } catch (e) {
    print('Error caching rooms: $e');
  }
}
// In cache_service.dart
List<RoomModel>? getCachedRooms({String key = 'all'}) {
  try {
    final timestamp = _timestampsBox.get('roomsTimestamp_$key');
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < roomsCacheDuration) {
      final roomsData = _roomsBox.get('rooms_$key');
      if (roomsData != null && roomsData is List) {
        // Ensure each item is a Map before converting
        return roomsData.map((item) {
          if (item is Map<String, dynamic>) {
            return RoomModel.fromJson(item);
          } else if (item is Map) {
            // Convert Map to Map<String, dynamic>
            return RoomModel.fromJson(Map<String, dynamic>.from(item));
          } else {
            print('⚠️ Invalid room data type: ${item.runtimeType}');
            return null;
          }
        }).whereType<RoomModel>().toList();
      }
    }
  } catch (e) {
    print('Error getting cached rooms: $e');
  }
  return null;
}
  Future<void> updateRoomInCache(RoomModel updatedRoom) async {
    final rooms = getCachedRooms();
    if (rooms != null) {
      final index = rooms.indexWhere((r) => r.code == updatedRoom.code);
      if (index != -1) {
        rooms[index] = updatedRoom;
        await cacheRooms(rooms);
      }
    }
  }

  // ========== MESSAGES CACHING ==========

  Future<void> cacheMessages(String roomCode, List<MessageModel> messages) async {
    final messagesMap = messages.map((m) => m.toString()).toList();
    await _messagesBox.put('messages_$roomCode', {'messages': messagesMap});
    await _timestampsBox.put('messagesTimestamp_$roomCode', DateTime.now());
  }

  List<MessageModel>? getCachedMessages(String roomCode) {
    final timestamp = _timestampsBox.get('messagesTimestamp_$roomCode');
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < messagesCacheDuration) {
      final data = _messagesBox.get('messages_$roomCode');
      if (data != null && data['messages'] != null) {
        return (data['messages'] as List)
            .map((json) => MessageModel.fromJson(json))
            .toList();
      }
    }
    return null;
  }

  Future<void> addMessageToCache(String roomCode, MessageModel message) async {
    final messages = getCachedMessages(roomCode) ?? [];
    messages.insert(0, message); // Add to beginning
    if (messages.length > 100) messages.removeLast(); // Keep only last 100
    await cacheMessages(roomCode, messages);
  }

  // ========== IMAGE CACHING ==========

  static final DefaultCacheManager imageCache = DefaultCacheManager();

  Future<FileInfo?> getImage(String url) async {
    try {
      return await imageCache.getFileFromCache(url);
    } catch (e) {
      print('Error getting cached image: $e');
      return null;
    }
  }

  Future<void> precacheImage(String url) async {
    try {
      await imageCache.downloadFile(url);
    } catch (e) {
      print('Error precaching image: $e');
    }
  }

  // ========== CACHE CLEARING ==========

  Future<void> clearRoomsCache() async {
    final keys = _roomsBox.keys.where((k) => k.toString().startsWith('rooms_'));
    for (var key in keys) {
      await _roomsBox.delete(key);
    }
    
    final timestampKeys = _timestampsBox.keys
        .where((k) => k.toString().startsWith('roomsTimestamp_'));
    for (var key in timestampKeys) {
      await _timestampsBox.delete(key);
    }
  }

  Future<void> clearMessagesCache(String? roomCode) async {
    if (roomCode != null) {
      await _messagesBox.delete('messages_$roomCode');
      await _timestampsBox.delete('messagesTimestamp_$roomCode');
    } else {
      final keys = _messagesBox.keys.where((k) => k.toString().startsWith('messages_'));
      for (var key in keys) {
        await _messagesBox.delete(key);
      }
      
      final timestampKeys = _timestampsBox.keys
          .where((k) => k.toString().startsWith('messagesTimestamp_'));
      for (var key in timestampKeys) {
        await _timestampsBox.delete(key);
      }
    }
  }

  Future<void> clearAllCache() async {
    await _userBox.clear();
    await _roomsBox.clear();
    await _messagesBox.clear();
    await _imagesBox.clear();
    await _timestampsBox.clear();
    await imageCache.emptyCache();
  }

  // ========== CACHE VALIDATION ==========

  bool isRoomsCacheValid({String key = 'all'}) {
    final timestamp = _timestampsBox.get('roomsTimestamp_$key');
    return timestamp != null && 
           DateTime.now().difference(timestamp) < roomsCacheDuration;
  }

  bool isMessagesCacheValid(String roomCode) {
    final timestamp = _timestampsBox.get('messagesTimestamp_$roomCode');
    return timestamp != null && 
           DateTime.now().difference(timestamp) < messagesCacheDuration;
  }
   Future<void> ensureBoxesAreOpen() async {
    if (!Hive.isBoxOpen('participantsBox')) {
      await Hive.openBox<List>('participantsBox');
    }
    if (!Hive.isBoxOpen('roomInfoBox')) {
      await Hive.openBox<Map>('roomInfoBox');
    }
  }

  // Add method to clear all room-related cache
  Future<void> clearAllRoomCache(String roomCode) async {
    await clearMessagesCache(roomCode);
    
    final participantsBox = await Hive.openBox<List>('participantsBox');
    await participantsBox.delete('participants_$roomCode');
    
    final roomInfoBox = await Hive.openBox<Map>('roomInfoBox');
    await roomInfoBox.delete('roomInfo_$roomCode');
    
    await _timestampsBox.delete('participantsTimestamp_$roomCode');
    await _timestampsBox.delete('roomInfoTimestamp_$roomCode');
  }
}