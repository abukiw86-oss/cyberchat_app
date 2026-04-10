
import 'package:cyberchat/screen/edit_profile_screen.dart'; 
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/rooms_model.dart';
import '../services/api_services/room_service.dart';
import '../services/api_services/auth_api.dart';
import '../screen/index.dart';
import '../widgets/create_room.dart';  

class UserDataDisplay extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final Function(UserModel)? onProfileUpdated; 

  const UserDataDisplay({
    super.key,
    required this.user,
    required this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<UserDataDisplay> createState() => _UserDataDisplayState();
}

class _UserDataDisplayState extends State<UserDataDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final RoomService _roomService = RoomService(); 
  final AuthService _authService = AuthService(); 
  final String baseurl = RoomService.imageurl; 
  
  List<RoomModel> _userRooms = [];
  bool _isLoadingRooms = true;

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
    _nameController.text = widget.user.displayName;
    _loadUserRooms();
  }

  Future<void> _loadUserRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await _roomService.fetchUsercreatedRooms(); // Fixed method name
      setState(() {
        _userRooms = rooms;
        _isLoadingRooms = false;
      });
    } catch (e) {
      setState(() => _isLoadingRooms = false);
      print('Error loading user rooms: $e');
    }
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CyberChatHomePage()),
        (route) => false,
      );
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: widget.user,
          onProfileUpdated: (updatedUser) {
            // Update local state
            setState(() {}); 
            if (widget.onProfileUpdated != null) {
              widget.onProfileUpdated!(updatedUser);
            }
          },
        ),
      ),
    );
  }

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRoomDialog(
        user: widget.user,
        onRoomCreated: (result) {
          // Refresh rooms after creation
          _loadUserRooms();
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room created successfully!'),
              backgroundColor: Color(0xFF00ff00),
            ),
          );
        },
      ),
    );
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
    String userImageUrl = '';
    if (widget.user.userLogo != null && widget.user.userLogo!.isNotEmpty) {
      userImageUrl = widget.user.userLogo!.startsWith('http') 
          ? widget.user.userLogo! 
          : '$baseurl/${widget.user.userLogo}';    
    } 
    return FloatingActionButton(
      onPressed: () => _showUserDataDialog(userImageUrl),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00ff00),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00ff00).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: _buildProfileImage(userImageUrl),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl) { 
    if (widget.user.userLogo != null && widget.user.userLogo!.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover, 
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00ff00)),
            ),
          );
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
            color: Color(0xFF00ff00),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showUserDataDialog(String userImageUrl) async {
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
                  child: _buildProfileContent(userImageUrl),
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

  Widget _buildProfileContent(String userImageUrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(userImageUrl),
          const SizedBox(height: 20),
          _buildUserStats(),
          const SizedBox(height: 20),
          _buildUserRoomsSection(),
          const SizedBox(height: 20),
          _buildBioSection(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String userImageUrl) {
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: widget.user.userLogo != null && widget.user.userLogo!.isNotEmpty
                ? Image.network(
                    userImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          widget.user.initials,
                          style: const TextStyle(
                            color: Color(0xFF00ff00),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      widget.user.initials,
                      style: const TextStyle(
                        color: Color(0xFF00ff00),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
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
                widget.user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Member since ${widget.user.memberSince}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
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

  Widget _buildBioSection() {
    if (!widget.user.hasBio) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00ffff).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BIO',
            style: TextStyle(
              color: Color(0xFF00ffff),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.bio!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
            icon: Icons.star,
            value: _userRooms.where((r) => r.isPublic).length.toString(),
            label: 'Public',
            color: const Color(0xFF00ffff),
          ),
          _buildStatItem(
            icon: Icons.lock,
            value: _userRooms.where((r) => !r.isPublic).length.toString(),
            label: 'Private',
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
                'YOUR ROOMS',
                style: TextStyle(
                  color: Color(0xFFFF00ff),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${_userRooms.length} total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoadingRooms)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF00ff)),
                ),
              ),
            )
          else if (_userRooms.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No rooms yet. Create your first room!',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const ScrollPhysics(),
              itemCount: _userRooms.length ,
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
                  '${room.participants} participant${room.participants != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
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
          child: _buildCyberSmallButton(
            onTap: _navigateToEditProfile,
            icon: Icons.edit,
            label: 'EDIT',
            color: const Color(0xFF00ffff),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCyberSmallButton(
            onTap: _showCreateRoomDialog,
            icon: Icons.add,
            label: 'CREATE',
            color: const Color(0xFF00ff00),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCyberSmallButton(
            onTap: _logout,
            icon: Icons.logout,
            label: 'LOGOUT',
            color: const Color.fromARGB(255, 255, 1, 1),
          ),
        ),
      ],
    );
  }

  Widget _buildCyberSmallButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}