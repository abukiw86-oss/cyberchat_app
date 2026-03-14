import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CookieService {
  static final CookieService _instance = CookieService._internal();
  factory CookieService() => _instance;
  CookieService._internal();

  Map<String, String> _cookies = {};

  void saveCookies(Map<String, String> headers) {
    final cookies = headers['set-cookie'];
    if (cookies != null && cookies.isNotEmpty) {
      final cookieList = cookies.split(',').map((e) => e.trim()).toList();
      
      for (var cookie in cookieList) {
        final parts = cookie.split(';');
        if (parts.isNotEmpty) {
          final keyValue = parts[0].split('=');
          if (keyValue.length == 2) {
            _cookies[keyValue[0].trim()] = keyValue[1].trim();
          }
        }
      }
      
      _persistCookies();
    }
  }

  Future<void> loadCookies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookiesString = prefs.getString('cookies');
      if (cookiesString != null && cookiesString.isNotEmpty) {
        _cookies = Map<String, String>.from(json.decode(cookiesString));
      }
    } catch (e) {
      print('Error loading cookies: $e');
      _cookies = {};
    }
  }
  
  Future<void> _persistCookies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cookies', json.encode(_cookies));
    } catch (e) {
      print('Error persisting cookies: $e');
    }
  }

  Future<Map<String, String>> getCookieHeader() async {
    await loadCookies();
    if (_cookies.isEmpty) return {};
    
    final cookieString = _cookies.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    return {'Cookie': cookieString};
  }

  Future<bool> isLoggedIn() async {
    await loadCookies();
    return _cookies.containsKey('visitor_id') && _cookies.containsKey('nickname');
  }

  Future<Map<String, String>> getCurrentUser() async {
    await loadCookies();
    return {
      'visitor_id': _cookies['visitor_id'] ?? '',
      'nickname': _cookies['nickname'] ?? '',
    };
  }
  
  Future<void> clearCookies() async {
    _cookies = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cookies');
    print('Cookies cleared');
  }
}