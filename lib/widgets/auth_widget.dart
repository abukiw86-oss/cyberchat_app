// lib/widgets/recovery_auth_dialog.dart
import 'package:flutter/material.dart';
import '../services/auth.dart';
import '../models/user_model.dart';

class RecoveryAuthDialog extends StatefulWidget {
  final Function(UserModel) onSuccess;

  const RecoveryAuthDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<RecoveryAuthDialog> createState() => _RecoveryAuthDialogState();
}

class _RecoveryAuthDialogState extends State<RecoveryAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _recoveryController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isCreateMode = true;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.authenticate(
        mode: _isCreateMode ? 'create' : 'login',
        recovery: _recoveryController.text.trim(),
        name: _nameController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(user);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF00ff00)),
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
              Text(
                _isCreateMode ? 'CREATE RECOVERY PHRASE' : 'ENTER RECOVERY PHRASE',
                style: const TextStyle(
                  color: Color(0xFF00ff00),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              
              // Recovery phrase input
              TextFormField(
                controller: _recoveryController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Recovery Phrase',
                  labelStyle: const TextStyle(color: Color(0xFF00ff00)),
                  hintText: 'e.g. my_safe_key_2025',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF00ff00).withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00ff00)),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF00ff)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recovery phrase';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                    return 'Only letters, numbers, hyphens, and underscores allowed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // Display name input
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: const TextStyle(color: Color(0xFF00ff00)),
                  hintText: 'Enter your display name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF00ff00).withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00ff00)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a display name';
                  }
                  if (value.length > 50) {
                    return 'Name too long (max 50 characters)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 10),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Important:',
                      style: TextStyle(
                        color: const Color(0xFF00ffff),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Your recovery phrase helps you return to your chat rooms anytime. '
                      'Keep it private and easy to remember.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF00ff).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFFFF00ff)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFF00ff), fontSize: 12),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ff00)),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00ff00),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(_isCreateMode ? 'Create' : 'Login'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isCreateMode = !_isCreateMode;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isCreateMode 
                          ? 'Already have a phrase? Login here' 
                          : 'Create a new recovery phrase',
                      style: const TextStyle(color: Color(0xFF00ffff), fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recoveryController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}