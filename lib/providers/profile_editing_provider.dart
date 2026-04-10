import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/api_services/profile_edit_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _selectedImage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  File? get selectedImage => _selectedImage;

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  Future<UserModel?> saveProfile({
    required String name,
    required String bio,
    required String? recoveryPhrase,
    required String? currentLogo,
    required String visitorId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result;
      if (_selectedImage != null) {
        result = await _userService.updateProfileWithImage(
          name: name,
          bio: bio,
          imageFile: _selectedImage,
          recoveryPhrase: recoveryPhrase,
        );
      } else {
        result = await _userService.updateUserProfile(
          name: name,
          bio: bio,
          recoveryPhrase: recoveryPhrase,
          userLogo: currentLogo,
        );
      }

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Profile updated!';
        final updatedUser = await _userService.getCurrentUserProfile(visitorid: visitorId);
        _selectedImage = null;
        return updatedUser;
      } else {
        _errorMessage = result['message'] ?? 'Update failed';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }
}