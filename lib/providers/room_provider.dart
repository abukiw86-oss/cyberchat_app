import 'dart:async';
import 'package:flutter/material.dart';
import '../models/rooms_model.dart';
import '../services/api_services/room_service.dart';
import '../services/api_services/auth_api.dart'; 
import '../models/user_model.dart'; 


class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();
  final AuthService _authService = AuthService();

  // State Variables
  List<RoomModel> _rooms = [];
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Getters
  List<RoomModel> get rooms => _rooms;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;   

  RoomProvider() {
    init();
  }

  Future<void> init() async {
    await loadSavedUser();
    await fetchRooms();
    _startRefreshTimer();
  }

  Future<void> loadSavedUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> fetchRooms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rooms = await _roomService.fetchRooms(forceRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchRooms();
    });
  }
  

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}