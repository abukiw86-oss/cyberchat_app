import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import 'timeStamp_cache.dart';

class UserCache{
  static final UserCache _instance = UserCache._internal();
  factory UserCache() => _instance;
  UserCache._internal();

  
  static const String userBoxName = 'UserData';
  static const String userTimeDuration = 'userTimestamp';
  static const Duration userCacheDuration = Duration(days: 365);

  final TimeStampService _timestampsBox =  TimeStampService();

  Box<UserModel> get _userBox => Hive.box<UserModel>(userBoxName);

  Future<void> cacheUser(UserModel user) async {
    await _userBox.put('currentUser', user);
    await _timestampsBox.saveTimestamp(userTimeDuration, DateTime.now());
  }

  UserModel? getCachedUser() {
    final timestamp = _timestampsBox.getTimestamp(userTimeDuration);
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < userCacheDuration) {
      return _userBox.get('currentUser');
    }
    return null;
  }
  
  Future<void> clearUserCache() async {
    await _userBox.delete('currentUser');
    await _timestampsBox.deleteTimestamp('userTimestamp');
  }
}