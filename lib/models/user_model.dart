import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final int? id;
  final String? name;
  final String? recoveryPhrase;
  final String? recoveryHash;
  final String? userLogo;
  final String? bio;
  final DateTime? createdAt;
  final bool isNew;

  UserModel({
    this.id,
    this.name,
    this.recoveryPhrase,
    this.recoveryHash,
    this.userLogo,
    this.bio,
    this.createdAt,
    this.isNew = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at']);
      }
    } catch (e) {
      createdAt = null;
    }

    bool isNew = false;
    if (createdAt != null) {
      isNew = createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
    }

    return UserModel(
      id: json['id'],
      name: json['name'] ?? json['nickname'],
      recoveryPhrase: json['recovery_phrase'],
      recoveryHash: json['recovery_hash'] ?? json['visitor_id'],
      userLogo: json['user_logo'],
      bio: json['bio'],
      createdAt: createdAt,
      isNew: json['is_new'] ?? isNew,
    );
  }
 

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'recovery_phrase': recoveryPhrase,
      'recovery_hash': recoveryHash,
      'user_logo': userLogo,
      'bio': bio,
      'created_at': createdAt?.toIso8601String(),
      'is_new': isNew,
    };
  }

   factory UserModel.guest() {
    return UserModel(
      name: 'Guest',
      recoveryHash: '',
      isNew: false,
    );
  }
  
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(toJson());
    await prefs.setString('user_data', userJson);
    await prefs.setBool('is_logged_in', true);
    print('✅ User data saved to SharedPreferences');
  }

  static Future<UserModel?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (!isLoggedIn) return null;
    
    final userJson = prefs.getString('user_data');
    if (userJson == null) return null;
    
    try {
      final Map<String, dynamic> jsonData = json.decode(userJson);
      return UserModel.fromJson(jsonData);
    } catch (e) {
      print('Error loading user from prefs: $e');
      return null;
    }
  }
 
  static Future<void> clearFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.setBool('is_logged_in', false);
    print('✅ User data cleared from SharedPreferences');
  }
 
   Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  bool get hasProfileImage => userLogo != null && userLogo!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;
  
  String get displayName => name ?? 'Unknown';
  
  String get initials{
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  String get memberSince {
    if (createdAt == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return 'Just now';
    }
  }
}