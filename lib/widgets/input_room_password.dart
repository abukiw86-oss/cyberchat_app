// lib/widgets/room_password_dialog.dart
import 'package:flutter/material.dart';
import '../models/rooms_model.dart';
import '../models/user_model.dart';
import '../services/get_rooms.dart';

class RoomPasswordDialog extends StatefulWidget {
  final RoomModel room;
  final UserModel user;
  final Function(Map<String, dynamic>) onSuccess;

  const RoomPasswordDialog({
    Key? key,
    required this.room,
    required this.user,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<RoomPasswordDialog> createState() => _RoomPasswordDialogState();
}

class _RoomPasswordDialogState extends State<RoomPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final RoomService _apiService = RoomService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFFF00ff)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF00ff)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Color(0xFFFF00ff),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRIVATE ROOM',
                          style: TextStyle(
                            color: Color(0xFFFF00ff),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          widget.room.code,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Password input
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room Password',
                  labelStyle: const TextStyle(color: Color(0xFFFF00ff)),
                  prefixIcon: const Icon(Icons.password, color: Color(0xFFFF00ff)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFFF00ff),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color(0xFFFF00ff).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder:  OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF00ff)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder:  OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the room password';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF00ff).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFFF00ff), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This room requires a password to join. Enter the invitation code provided by the room creator.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF00ff)),
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
                        onPressed: _joinPrivateRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF00ff),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('JOIN ROOM'),
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

Future<void> _joinPrivateRoom() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final result = await _apiService.checkRoomPassword(
      roomCode: widget.room.code,
      password: _passwordController.text,
      nickname: widget.user.displayName,
    );

    if (result['success']) {
      Navigator.pop(context);
      widget.onSuccess(result);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Invalid password';
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
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}