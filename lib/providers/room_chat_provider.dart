import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import '../models/message_model.dart';
import '../services/api_services/chat_service.dart';
import '../services/api_services/room_service.dart';

class ChatProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();
  final RoomApiService _apiService = RoomApiService();
   
  final List<MessageModel> _messages = [];
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _bannedUsers = [];
   
  final ScrollController _scrollController = ScrollController();

   
  bool _isLoading = true;
  bool _isSending = false;
  bool _isCreator = false;
  String? _inviteCode;
  int _lastMessageId = 0;
  Timer? _refreshTimer;
 
  List<MessageModel> get messages => _messages;
  List<Map<String, dynamic>> get participants => _participants;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isCreator => _isCreator;
  String? get inviteCode => _inviteCode;

  Future<void> initializeRoom(String roomCode, String nickname, String roomType) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _roomService.joinRoom(
        roomCode: roomCode,
        nickname: nickname,
        roomType: roomType,
      );

      if (result['success']) {
        _isCreator = result['is_creator'] ?? false;
        _inviteCode = result['invite_code'];
        _isLoading = false;
        notifyListeners();
        
        await loadParticipants(roomCode);
        startMessagePolling(roomCode);
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; 
    }
  }

  void startMessagePolling(String roomCode) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      loadMessages(roomCode);
    });
  }

  Future<void> loadMessages(String roomCode) async {
    try {
      final newMessages = await _apiService.getMessages(
        roomCode,
        lastId: _lastMessageId,
      );
      
      if (newMessages.isNotEmpty) {
        _messages.addAll(newMessages);
        _lastMessageId = _messages.last.id;
        _scrollToBottom();
        notifyListeners();  
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
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

  Future<void> sendMessage(String roomCode, String message, String nickname) async {
    if (message.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    final success = await _apiService.sendMessage(
      roomCode: roomCode,
      message: message,
      nickname: nickname,
    );

    if (success) {
      await loadMessages(roomCode);
    }
    
    _isSending = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> uploadImages(String roomCode, String nickname) async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isEmpty) return {'success': false, 'message': 'No files picked'};

    _isLoading = true;
    notifyListeners();

    List<File> files = pickedFiles.map((f) => File(f.path)).toList();
    
    final result = await _apiService.uploadFiles(
      roomCode: roomCode,
      nickname: nickname,
      files: files,
    );

    if (result['success'] ?? false) {
      await loadMessages(roomCode);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> loadParticipants(String roomCode) async {
    final participants = await _apiService.getParticipants(roomCode);
    _participants = participants;
    notifyListeners();
  }
  
  Future<String?> pickAndUploadFiles({
  required String roomCode,
  required String nickname,
}) async {
  final picker = ImagePicker();
  final List<XFile> pickedFiles = await picker.pickMultiImage();

  if (pickedFiles.isEmpty) return null;  

  _isLoading = true;
  notifyListeners();

  try {
    List<File> files = pickedFiles.map((f) => File(f.path)).toList();

    final result = await _apiService.uploadFiles(
      roomCode: roomCode,
      nickname: nickname,
      files: files,
    );

    if (result['success'] ?? false) {
      await loadMessages(roomCode);
      _isLoading = false;
      notifyListeners();
      return "SUCCESS";  
    } else {
      _isLoading = false;
      notifyListeners();
      return result['message'] ?? 'Upload failed';
    }
  } catch (e) {
    _isLoading = false;
    notifyListeners();
    return 'Error: $e';
  }
}
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}