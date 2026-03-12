// lib/widgets/user_data_display.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/rooms_model.dart';
import '../services/get_rooms.dart';
import '../services/cookie_service.dart';
import '../services/auth.dart';

class UserDataDisplay extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const UserDataDisplay({
    Key? key,
    required this.user,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<UserDataDisplay> createState() => _UserDataDisplayState();
}

class _UserDataDisplayState extends State<UserDataDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final RoomService _apiService = RoomService();
  final CookieService _cookieService = CookieService();
  final AuthService _authService = AuthService();
  
  List<RoomModel> _userRooms = [];
  bool _isLoadingRooms = true;
  String? _profileImageUrl;
  bool _isEditing = false;

  // Controllers for edit mode
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _nameController.text = widget.user.name;
    _loadUserRooms();
    _loadUserProfile();
  }

  Future<void> _loadUserRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await _apiService.fetchUserRooms();
      setState(() {
        _userRooms = rooms;
        _isLoadingRooms = false;
      });
    } catch (e) {
      setState(() => _isLoadingRooms = false);
      print('Error loading user rooms: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    //TODO
    // You can implement this based on your backend
  }

  Future<void> _updateProfile() async {
    // Implement profile update logic
    setState(() {
      _isEditing = false;
      // Update user name if changed
    });
  }

  Future<void> _uploadProfileImage() async {
    // Implement image picker and upload
    // You can use image_picker package
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Logout',
          style: TextStyle(color: Color(0xFFFF00ff)),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF00ff),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      widget.onLogout();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showUserDataDialog(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00ff00),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00ff00).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _profileImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Image.network(
                  _profileImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar();
                  },
                ),
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Color(0xFF00ff00),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showUserDataDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: const Color(0xFF00ff00),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00ff00).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDialogHeader(),
                Expanded(
                  child: _isEditing ? _buildEditProfile() : _buildProfileContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00ff00).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            color: Color(0xFF00ff00),
            size: 24,
          ),
          const SizedBox(width: 10),
          const Text(
            'USER PROFILE',
            style: TextStyle(
              color: Color(0xFF00ff00),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF00ff00)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildUserStats(),
          const SizedBox(height: 20),
          _buildUserRoomsSection(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        // Profile Image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF00ff00),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00ff00).withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: _profileImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Color(0xFF00ff00),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 20),
        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Member since ${_formatDate(widget.user.isNew.toString())}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ff00).withOpacity(0.2),
                  border: Border.all(
                    color: const Color(0xFF00ff00),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.user.isNew ? '🆕 NEW USER' : '👑 ACTIVE USER',
                  style: const TextStyle(
                    color: Color(0xFF00ff00),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00ffff).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.meeting_room,
            value: '${_userRooms.length}',
            label: 'Rooms',
            color: const Color(0xFF00ff00),
          ),
          _buildStatItem(
            icon: Icons.message,
            value: _calculateTotalMessages(),
            label: 'Messages',
            color: const Color(0xFF00ffff),
          ),
          _buildStatItem(
            icon: Icons.star,
            value: _calculateCreatorRooms(),
            label: 'Created',
            color: const Color(0xFFFF00ff),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRoomsSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFFF00ff).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Color(0xFFFF00ff),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  color: Color(0xFFFF00ff),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${_userRooms.length} rooms',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoadingRooms)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF00ff)),
              ),
            )
          else if (_userRooms.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No rooms yet. Create or join a room!',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userRooms.length > 5 ? 5 : _userRooms.length,
              itemBuilder: (context, index) {
                final room = _userRooms[index];
                return _buildActivityItem(room);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RoomModel room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: room.isPublic ? const Color(0xFF00ff00) : const Color(0xFFFF00ff),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                room.isPublic ? '🌐' : '🔒',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${room.participants} participants',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(room.lastActive),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
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
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => _isEditing = true);
            },
            icon: const Icon(Icons.edit, color: Colors.black),
            label: const Text('EDIT PROFILE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ffff),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.black),
            label: const Text('LOGOUT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF00ff),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile image with edit option
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF00ffff),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: _profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(48),
                        child: Image.network(
                          _profileImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Color(0xFF00ffff),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: const Color(0xFF00ffff)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF00ffff), size: 20),
                    onPressed: _uploadProfileImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Edit name field
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: const TextStyle(color: Color(0xFF00ffff)),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF00ffff)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF00ffff).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder:  OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00ffff)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          // Bio field
          TextFormField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio',
              labelStyle: const TextStyle(color: Color(0xFF00ffff)),
              prefixIcon: const Icon(Icons.info, color: Color(0xFF00ffff)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF00ffff).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder:  OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00ffff)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Save/Cancel buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                  },
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
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ffff),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('SAVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTotalMessages() {
    // Implement based on your data
    return '42';
  }

  String _calculateCreatorRooms() {
    // Count rooms where user is creator
    return '3';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}