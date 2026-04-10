import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../services/api_services/auth_api.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
 
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  UserProvider() {
    _init();
  } 
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.getCurrentUser();
    _isLoading = false;
    notifyListeners();
  }
 
  Future<void> authenticate(String mode, String recovery, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.authenticate(
        mode: mode, 
        recovery: recovery, 
        name: name
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
 
  Future<void> updateName(String newName) async {
    if (_user == null) return;
     
    final updatedUser = UserModel(
      id: _user!.id,
      name: newName,
      recoveryHash: _user!.recoveryHash,
      userLogo: _user!.userLogo,
      bio: _user!.bio,
      createdAt: _user!.createdAt,
    );

    await _syncUser(updatedUser);
  }
 
  Future<void> updateProfileImage(String imageUrl) async {
    if (_user == null) return;

    final updatedUser = UserModel(
      id: _user!.id,
      name: _user!.name,
      recoveryHash: _user!.recoveryHash,
      userLogo: imageUrl,
      bio: _user!.bio,
      createdAt: _user!.createdAt,
    );

    await _syncUser(updatedUser);
  }
 
  Future<void> updateBio(String newBio) async {
    if (_user == null) return;

    final updatedUser = UserModel(
      id: _user!.id,
      name: _user!.name,
      recoveryHash: _user!.recoveryHash,
      userLogo: _user!.userLogo,
      bio: newBio,
      createdAt: _user!.createdAt,
    );

    await _syncUser(updatedUser);
  }
 
  Future<void> _syncUser(UserModel updatedUser) async {
    _user = updatedUser; 
    await _authService.saveToSecureStorage(updatedUser);
    notifyListeners();  
  }
}