import 'package:hive_flutter/hive_flutter.dart';

class TimeStampService {
  static const String timestampsBoxName = 'timestampsBox';
  Box<DateTime> get _box => Hive.box<DateTime>(timestampsBoxName);

  Future<void> saveTimestamp(String key, DateTime time) async {
    await _box.put(key, time);
    print('Saved timestamp for $key: $time');
  }

  DateTime? getTimestamp(String key) {
    return _box.get(key);
  }

  Future<void> deleteTimestamp(String key) async {
    await _box.delete(key);
}
  Future <void> clear() async{
    await _box.clear();
    print('timestamps cleared');
  }
List<dynamic> get allKeys => _box.keys.toList();
}