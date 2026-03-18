import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/rooms_model.dart';
import 'timeStamp_cache.dart';

class RoomCacheService {
  static final RoomCacheService _instance = RoomCacheService._internal();
  factory RoomCacheService() => _instance;
  RoomCacheService._internal();

  final TimeStampService _timestampsBox =  TimeStampService();

  static const String roomsBoxName = 'roomsBox';
  static const String imagesBoxName = 'imagesBox';

  // Cache durations
  static const Duration roomsCacheDuration = Duration(days: 30);

  Box<List> get _roomsBox => Hive.box<List>(roomsBoxName);
  Box<String> get _imagesBox => Hive.box<String>(imagesBoxName);

// room caching 
Future<void> cacheRooms(List<RoomModel> rooms, {String key = 'all'}) async {
  try {
    final roomsMap = rooms.map((r) => r.toJson()).toList();
    await _roomsBox.put('rooms_$key', roomsMap);
    await _timestampsBox.saveTimestamp('roomsTimestamp_$key', DateTime.now());
    print(' Cached ${rooms.length} rooms with key: $key');
  } catch (e) {
    print('Error caching rooms: $e');
  }
}

List<RoomModel>? getCachedRooms({String key = 'all'}) {
  try {
    final timestamp = _timestampsBox.getTimestamp('roomsTimestamp_$key');
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < roomsCacheDuration) {
      final roomsData = _roomsBox.get('rooms_$key');
      if (roomsData != null && roomsData is List) {
        return roomsData.map((item) {
          if (item is Map<String, dynamic>) {
            return RoomModel.fromJson(item);
          } else if (item is Map) {
            return RoomModel.fromJson(Map<String, dynamic>.from(item));
          } else {
            print('Invalid room data type: ${item.runtimeType}');
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


  //image caching
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
      print(url);
    } catch (e) {
      print('Error precaching image: $e');
    }
  }

  // clear caches manually
  Future<void> clearRoomsCache() async {
    final keys = _roomsBox.keys.where((k) => k.toString().startsWith('rooms_'));
    for (var key in keys) {
      await _roomsBox.delete(key);
    }
    
    final timestampKeys = _timestampsBox.allKeys
        .where((k) => k.toString().startsWith('roomsTimestamp_'));
    for (var key in timestampKeys) {
      await _timestampsBox.deleteTimestamp(key);
    }
  }


  Future<void> clearAllCache() async {
    await _roomsBox.clear();
    await _imagesBox.clear();
    await _timestampsBox.clear();
    await imageCache.emptyCache();
  }

  bool isRoomsCacheValid({String key = 'all'}) {
    final timestamp = _timestampsBox.getTimestamp('roomsTimestamp_$key');
    return timestamp != null && 
           DateTime.now().difference(timestamp) < roomsCacheDuration;
  }

   Future<void> ensureBoxesAreOpen() async {
    if (!Hive.isBoxOpen('participantsBox')) {
      await Hive.openBox<List>('participantsBox');
    }
    if (!Hive.isBoxOpen('roomInfoBox')) {
      await Hive.openBox<Map>('roomInfoBox');
    }
  }

  Future<void> clearAllRoomCache(String roomCode) async {
    
    final participantsBox = await Hive.openBox<List>('participantsBox');
    await participantsBox.delete('participants_$roomCode');
    
    final roomInfoBox = await Hive.openBox<Map>('roomInfoBox');
    await roomInfoBox.delete('roomInfo_$roomCode');
    
    await _timestampsBox.deleteTimestamp('participantsTimestamp_$roomCode');
    await _timestampsBox.deleteTimestamp('roomInfoTimestamp_$roomCode');
  }
}