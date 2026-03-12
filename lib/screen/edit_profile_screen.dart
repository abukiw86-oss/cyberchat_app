// lib/screens/editprofile.dart
import 'package:cyberchat/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cyberchat/models/user_model.dart';
import 'package:cyberchat/services/profile_edit_service.dart'; 

class EditProfile extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onProfileUpdated;

  const EditProfile({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _recoveryPhraseController;
  
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isEditing = true; 
  String? _errorMessage;
  String? _successMessage;

  bool _obscureRecoveryPhrase = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _recoveryPhraseController = TextEditingController(text: widget.user.recoveryPhrase ?? '');
    _imageUrl = '${RoomApiService.baseUrl}/${widget.user.userLogo}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _recoveryPhraseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageUrl = null; 
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Change Profile Picture',
          style: TextStyle(color: Color(0xFF00ffff)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00ffff)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00ffff)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_imageUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

Future<void> _updateProfile() async {
  if (_nameController.text.trim().isEmpty) {
    _showError('Name cannot be empty');
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
  });

  try {
    Map<String, dynamic> result;
    
    if (_selectedImage != null) {
      result = await _userService.updateProfileWithImage(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        imageFile: _selectedImage,
        recoveryPhrase: _recoveryPhraseController.text.trim().isNotEmpty 
            ? _recoveryPhraseController.text.trim() 
            : null,
      );
    } else {
      result = await _userService.updateUserProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        recoveryPhrase: _recoveryPhraseController.text.trim().isNotEmpty 
            ? _recoveryPhraseController.text.trim() 
            : null,
        userLogo: _imageUrl,
      );
    }

    if (result['success'] == true) {
      final updatedUser = await _userService.getCurrentUser();
      
      setState(() {
        _isLoading = false;
        _successMessage = result['message'] ?? 'Profile updated successfully!';
        if (result['user'] != null) {
          _imageUrl = result['user']['user_logo'];
        }
        _selectedImage = null;
      });
      widget.onProfileUpdated(updatedUser);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, updatedUser);
        }
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'] ?? 'Failed to update profile';
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Error: $e';
    });
  }
}
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF00ff),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildEditProfile(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF00ff00)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'EDIT PROFILE',
        style: TextStyle(
          color: Color(0xFF00ffff),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isEditing ? Icons.visibility : Icons.edit,
            color: const Color(0xFF00ffff),
          ),
          onPressed: () {
            setState(() {
              _isEditing = !_isEditing;
            });
          },
          tooltip: _isEditing ? 'Preview' : 'Edit',
        ),
      ],
    );
  }

  Widget _buildEditProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: 20),
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00ff00).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF00ff00)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00ff00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Color(0xFF00ff00)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF00ff).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFFF00ff)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Color(0xFFFF00ff)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFF00ff)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Edit Name Field
          _buildEditableField(
            label: 'Display Name',
            icon: Icons.person,
            controller: _nameController,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name cannot be empty';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Bio Field
          _buildEditableField(
            label: 'Bio',
            icon: Icons.info,
            controller: _bioController,
            maxLines: 3,
            enabled: _isEditing,
            hint: 'Tell us about yourself...',
          ),
          const SizedBox(height: 15),

          // Recovery Phrase Field (read-only for security)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF00ffff).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key, color: Color(0xFF00ffff), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Recovery Phrase',
                      style: TextStyle(
                        color: Color(0xFF00ffff),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _obscureRecoveryPhrase ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF00ffff),
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureRecoveryPhrase = !_obscureRecoveryPhrase;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _obscureRecoveryPhrase 
                      ? '•' * (_recoveryPhraseController.text.length)
                      : _recoveryPhraseController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recovery phrase cannot be changed for security reasons',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account Info Section
          _buildAccountInfo(),
          const SizedBox(height: 20),

          // Action Buttons
          if (_isEditing) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF00ffff),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00ffff).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(58),
            child: _buildProfileImageContent(),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: const Color(0xFF00ffff)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Color(0xFF00ffff), size: 20),
                onPressed: _showImageSourceDialog,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImageContent() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar();
        },
      );
    } else {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: Center(
        child: Text(
          widget.user.initials,
          style: const TextStyle(
            color: Color(0xFF00ffff),
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? const Color(0xFF00ffff) : Colors.grey,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: enabled ? const Color(0xFF00ffff) : Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: enabled 
                ? const Color(0xFF00ffff).withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: enabled ? const Color(0xFF00ffff) : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFFF00ff).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACCOUNT INFORMATION',
            style: TextStyle(
              color: Color(0xFFFF00ff),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Member Since', widget.user.memberSince),
          _buildInfoRow('Account Status', widget.user.isNew ? '🆕 New' : '👑 Active'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFFFF00ff),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ffff),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text('SAVE'),
          ),
        ),
      ],
    );
  }
}