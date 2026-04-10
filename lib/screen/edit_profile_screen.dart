import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../providers/Profile_editing_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onProfileUpdated;

  const EditProfileScreen({super.key, required this.user, required this.onProfileUpdated});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isEditing = true;
  bool _obscureRecovery = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileImage(provider),
            const SizedBox(height: 25),
            
            // Status Messages
            if (provider.successMessage != null) _buildStatusBox(provider.successMessage!, const Color(0xFF00ff00)),
            if (provider.errorMessage != null) _buildStatusBox(provider.errorMessage!, const Color(0xFFFF00ff)),

            // Form Fields
            _buildEditableField(
              label: 'DISPLAY NAME',
              icon: Icons.person,
              controller: _nameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 15),
            _buildEditableField(
              label: 'BIO',
              icon: Icons.info_outline,
              controller: _bioController,
              maxLines: 3,
              enabled: _isEditing,
              hint: 'System status...',
            ),
            const SizedBox(height: 15),
            _buildRecoveryField(),
            const SizedBox(height: 20),
            
            _buildAccountInfo(),
            const SizedBox(height: 25),

            if (_isEditing) _buildActionButtons(provider),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Text('EDIT PROFILE', style: TextStyle(color: Color(0xFF00ffff), fontWeight: FontWeight.bold, letterSpacing: 2)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF00ff00)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.visibility : Icons.edit, color: const Color(0xFF00ffff)),
          onPressed: () => setState(() => _isEditing = !_isEditing),
        ),
      ],
    );
  }

  Widget _buildProfileImage(ProfileProvider provider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00ffff), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFF00ffff).withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: provider.selectedImage != null
                ? Image.file(provider.selectedImage!, fit: BoxFit.cover)
                : (widget.user.hasProfileImage 
                    ? Image.network(widget.user.userLogo!, fit: BoxFit.cover)
                    : Center(child: Text(widget.user.initials, style: const TextStyle(color: Color(0xFF00ffff), fontSize: 40, fontWeight: FontWeight.bold)))),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: () => _showImageSourceDialog(provider),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00ffff))),
                child: const Icon(Icons.camera_alt, color: Color(0xFF00ffff), size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBox(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(color == Colors.green ? Icons.check_circle : Icons.error, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildEditableField({required String label, required IconData icon, required TextEditingController controller, int maxLines = 1, bool enabled = true, String? hint}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: enabled ? const Color(0xFF00ffff) : Colors.grey, fontSize: 12),
        prefixIcon: Icon(icon, color: enabled ? const Color(0xFF00ffff) : Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00ffff).withOpacity(0.3))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00ffff))),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      ),
    );
  }

  Widget _buildRecoveryField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00ffff).withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RECOVERY PHRASE', style: TextStyle(color: Color(0xFF00ffff), fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(_obscureRecovery ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF00ffff), size: 18),
                onPressed: () => setState(() => _obscureRecovery = !_obscureRecovery),
              )
            ],
          ),
          Text(
            _obscureRecovery ? '•' * 20 : (widget.user.recoveryPhrase ?? 'NOT_SET'),
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
          const Text('PHRASE CANNOT BE MODIFIED', style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFF00ff).withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACCOUNT INFO', style: TextStyle(color: Color(0xFFFF00ff), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('MEMBER SINCE: ${widget.user.memberSince}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('STATUS: ${widget.user.isNew ? "NEW_RECRUIT" : "ELITE_USER"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ProfileProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: provider.isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : () async {
              final updated = await provider.saveProfile(
                name: _nameController.text,
                bio: _bioController.text,
                recoveryPhrase: widget.user.recoveryPhrase,
                currentLogo: widget.user.userLogo,
                visitorId: widget.user.recoveryHash.toString(),
              );
              if (updated != null) {
                widget.onProfileUpdated(updated);
                Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ffff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)),
            child: provider.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('SAVE CHANGES'),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(side: BorderSide(color: Color(0xFF00ffff))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera, color: Color(0xFF00ffff)), title: const Text('Camera', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); provider.pickImage(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.image, color: Color(0xFF00ffff)), title: const Text('Gallery', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); provider.pickImage(ImageSource.gallery); }),
          if (provider.selectedImage != null) ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Remove', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); provider.clearImage(); }),
        ],
      ),
    );
  }
}