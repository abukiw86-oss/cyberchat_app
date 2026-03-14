// lib/screen/chat_room_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/rooms_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/cookie_service.dart';
import '../services/get_rooms.dart';

class ChatRoomPage extends StatefulWidget {
  final RoomModel room;
  final UserModel user;

  const ChatRoomPage({
    super.key,
    required this.room,
    required this.user,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final RoomService _roomservice = RoomService();
  final RoomApiService _apiService = RoomApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<MessageModel> _messages = [];
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _bannedUsers = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isCreator = false;
  String? _inviteCode;
  Timer? _refreshTimer;
  int _lastMessageId = 0;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
    _startMessageRefresh();
  }

  Future<void> _initializeRoom() async {
    try {
      final result = await _roomservice.joinRoom(
        roomCode: widget.room.code,
        nickname: widget.user.displayName,
        roomType: widget.room.status,
      );

      if (result['success']) {
        setState(() {
          _isCreator = result['is_creator'] ?? false;
          _inviteCode = result['invite_code'];
          _isLoading = false;
        });
        await _loadParticipants();
        await _loadMessages();
      } else {
        // Handle error
        _showError(result['message']);
      }
    } catch (e) {
      _showError('Failed to join room: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startMessageRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _apiService.getMessages(
        widget.room.code,
        lastId: _lastMessageId,
      );
      
      if (messages.isNotEmpty && mounted) {
        setState(() {
          _messages.addAll(messages);
          _lastMessageId = _messages.last.id;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _loadParticipants() async {
    final participants = await _apiService.getParticipants(widget.room.code);
    if (mounted) {
      setState(() {
        _participants = participants;
      });
    }
  }

  Future<void> _loadBannedUsers() async {
    if (!_isCreator) return;
    
    final banned = await _apiService.getBannedUsers(widget.room.code);
    if (mounted) {
      setState(() {
        _bannedUsers = banned;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);

    final success = await _apiService.sendMessage(
      roomCode: widget.room.code,
      message: message,
      nickname: widget.user.displayName,
    );

    if (success && mounted) {
      _messageController.clear();
      await _loadMessages();
    }

    setState(() => _isSending = false);
  }

  Future<void> _pickAndUploadFiles() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isEmpty) return;

    setState(() => _isLoading = true);

    List<File> files = pickedFiles.map((f) => File(f.path)).toList();
    
    final result = await _apiService.uploadFiles(
      roomCode: widget.room.code,
      nickname: widget.user.displayName,
      files: files,
    );

    if (result['success'] ?? false) {
      _showMessage('Files uploaded successfully');
      await _loadMessages();
    } else {
      _showError(result['message'] ?? 'Upload failed');
    }

    setState(() => _isLoading = false);
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Participants (${_participants.length})',
          style: const TextStyle(color: Color(0xFF00ff00)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final participant = _participants[index];
              return ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF00ffff)),
                title: Text(
                  participant['nickname'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Last seen: ${participant['last_joined']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 255, 47, 0),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00ff00),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _buildMessagesList(),
                ),
                _buildInputArea(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF00ff00)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00ff00),
                  ),
                ),
                Text(
                  '${_participants.length} participants',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00ffff),
                  ),
                ),
              ],
            ),
          ),
          if (_isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF00ff)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CREATOR',
                style: TextStyle(
                  color: Color(0xFFFF00ff),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.people, color: Color(0xFF00ffff)),
          onPressed: _showParticipantsDialog,
        ),
        IconButton(
          icon: const Icon(Icons.info, color: Color(0xFF00ff00)),
          onPressed: _showRoomInfoDialog,
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: const Color(0xFF00ff00).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: const Color(0xFF00ff00).withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the conversation!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isSelf = message.visitorHash == _getVisitorId();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf) _buildAvatar(message),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.nickname,
                  style: TextStyle(
                    color: isSelf ? const Color(0xFFFF00ff) : const Color(0xFF00ffff),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelf
                        ? const Color(0xFFFF00ff).withOpacity(0.1)
                        : const Color(0xFF00ff00).withOpacity(0.1),
                    border: Border.all(
                      color: isSelf ? const Color(0xFFFF00ff) : const Color(0xFF00ff00),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.filePaths.isNotEmpty)
                        ...message.filePaths.map((url) => _buildFileWidget(url, isSelf)),
                      if (message.message.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: message.filePaths.isNotEmpty ? 8 : 0),
                          child: Text(
                            message.message,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSelf) _buildAvatar(message),
        ],
      ),
    );
  }

  Widget _buildAvatar(MessageModel message) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: message.visitorHash == _getVisitorId()
              ? const Color(0xFFFF00ff)
              : const Color(0xFF00ff00),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: message.userLogo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                message.userLogo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      message.nickname[0].toUpperCase(),
                      style: TextStyle(
                        color: message.visitorHash == _getVisitorId()
                            ? const Color(0xFFFF00ff)
                            : const Color(0xFF00ff00),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                message.nickname[0].toUpperCase(),
                style: TextStyle(
                  color: message.visitorHash == _getVisitorId()
                      ? const Color(0xFFFF00ff)
                      : const Color(0xFF00ff00),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildFileWidget(String url, bool isSelf) {
    final isImage = url.toLowerCase().isEmpty;
    
    if (isImage) {
      return GestureDetector(
        onTap: () => _showImageDialog(url),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                url.split('/').last,
                style: const TextStyle(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00ff00).withOpacity(0.3),
          ),
        ),
        color: Colors.black,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Color(0xFF00ffff)),
            onPressed: _pickAndUploadFiles,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color(0xFF00ff00).withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: const Color(0xFF00ff00).withOpacity(0.3),
                  ),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00ff00)),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ff00)),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00ff00)),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }

  void _showRoomInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Room Info',
          style: TextStyle(color: Color(0xFF00ff00)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Room Code', widget.room.code),
            _buildInfoRow('Status', widget.room.status == 'public' ? 'Public' : 'Private'),
            _buildInfoRow('Participants', '${_participants.length}'),
            _buildInfoRow('Your Role', _isCreator ? 'Creator' : 'Member'),
            if (_inviteCode != null && _inviteCode!.isNotEmpty) ...[
              const Divider(color: Color(0xFF00ff00)),
              const Text(
                'Invite Code:',
                style: TextStyle(color: Color(0xFF00ffff), fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _inviteCode!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
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
            style: const TextStyle(color: Color(0xFF00ffff), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  String _getVisitorId() {
    return widget.user.recoveryHash.toString();
  }
}