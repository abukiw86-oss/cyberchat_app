// lib/widgets/create_room_dialog.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/rooms_model.dart';
import '../services/get_rooms.dart'; 
import 'input_room_password.dart'; 

class CreateRoomDialog extends StatefulWidget {
  final UserModel user;
  final Function(Map<String, dynamic>) onRoomCreated;

  const CreateRoomDialog({
    super.key,
    required this.user,
    required this.onRoomCreated,
  });

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  final RoomService _roomService = RoomService(); 
  
  String _roomType = 'public';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF00ffff)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00ffff)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF00ffff),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CREATE / JOIN NEW ROOM',
                    style: TextStyle(
                      color: Color(0xFF00ffff),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Room Code Input
              TextFormField(
                controller: _roomCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room Code',
                  labelStyle: const TextStyle(color: Color(0xFF00ffff)),
                  hintText: 'e.g. my_chat_room',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.tag, color: Color(0xFF00ffff)),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room code';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                    return 'Only letters, numbers, hyphens, and underscores allowed';
                  }
                  if (value.length < 3) {
                    return 'Room code must be at least 3 characters';
                  }
                  if (value.length > 20) {
                    return 'Room code must be less than 20 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),

              // Room Type Selection
              const Text(
                'Room Type',
                style: TextStyle(
                  color: Color(0xFF00ffff),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRoomTypeOption(
                      type: 'public',
                      icon: Icons.public,
                      label: 'Public',
                      color: const Color(0xFF00ff00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoomTypeOption(
                      type: 'private',
                      icon: Icons.lock,
                      label: 'Private',
                      color: const Color(0xFFFF00ff),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _roomType == 'public'
                        ? const Color(0xFF00ff00).withOpacity(0.3)
                        : const Color(0xFFFF00ff).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _roomType == 'public' ? Icons.public : Icons.lock,
                      color: _roomType == 'public'
                          ? const Color(0xFF00ff00)
                          : const Color(0xFFFF00ff),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _roomType == 'public'
                            ? 'Anyone can join this room without an invite code'
                            : 'Only people with the invite code can join this room',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF00ff).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFFFF00ff)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF00ff),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFFF00ff),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Loading Indicator or Buttons
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ffff)),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createOrJoinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00ffff),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('CREATE ROOM'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTypeOption({
    required String type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _roomType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _roomType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : color.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : color.withOpacity(0.5),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createOrJoinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _roomService.joinRoom(
        roomCode: _roomCodeController.text.trim(),
        nickname: widget.user.displayName,
        roomType: _roomType,
      );

      print('Create room result: $result'); 

      if (result['success'] == true) {
        Navigator.pop(context); 
        widget.onRoomCreated(result);
      } 
      else if (result['requires_password'] == true) {
        final room = RoomModel(
          code: _roomCodeController.text.trim(),
          participants: 0,
          lastActive: DateTime.now().toIso8601String(),
          nickname: widget.user.displayName,
          status: 'private',
          logoPath: '',
          userLimits: '0',
        );

        _showPasswordDialog(room);
      }
      else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to create/join room';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPasswordDialog(RoomModel room) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoomPasswordDialog(
        room: room,
        user: widget.user, 
        onSuccess: (result) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Successfully joined ${room.code}!'),
              backgroundColor: const Color(0xFFFF00ff),
              duration: const Duration(seconds: 2),
            ),
          );
          widget.onRoomCreated(result);
        },
      ),
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }
}