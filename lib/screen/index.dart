import 'package:cyberchat/providers/userProvider.dart';
import 'package:cyberchat/widgets/appBar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/background_matrix.dart';
import '../widgets/user_data_display.dart';
import 'dart:async';
import 'dart:math';
import '../models/rooms_model.dart';
import '../services/api_services/room_service.dart'; 
import '../screen/chat_screen.dart';
import '../models/user_model.dart';
import '../widgets/auth_widget.dart'; 
import '../widgets/handle_errors_in_scaffoldOfMessenger.dart'; 
import '../providers/room_provider.dart';

class CyberChatHomePage extends StatefulWidget {
  const CyberChatHomePage({super.key});

  @override
  State<CyberChatHomePage> createState() => _CyberChatHomePageState();
}

class _CyberChatHomePageState extends State<CyberChatHomePage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final Random _random = Random();
  late Timer _matrixTimer;
  final List<MatrixSymbol> _matrixSymbols = [];

  @override
  void initState() {
    super.initState();
    
    // 1. Safe Provider Access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        roomProvider.loadSavedUser();
        roomProvider.fetchRooms(); 
      }
    });

    // 2. Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 3. Matrix Setup
    for (int i = 0; i < 30; i++) {
      _matrixSymbols.add(MatrixSymbol(
        position: Offset(_random.nextDouble() * 400, _random.nextDouble() * 800),
        symbol: _getRandomMatrixSymbol(),
      ));
    }

    _matrixTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          for (var symbol in _matrixSymbols) {
            if (_random.nextDouble() > 0.7) symbol.symbol = _getRandomMatrixSymbol();
            symbol.position = Offset(symbol.position.dx, symbol.position.dy + _random.nextDouble() * 5);
            if (symbol.position.dy > 800) symbol.position = Offset(symbol.position.dx, 0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matrixTimer.cancel(); 
    super.dispose();
  }

  String _getRandomMatrixSymbol() {
    const String chars = '0101010101001001001001001001010101010101010101010101010101010010101';
    return chars[_random.nextInt(chars.length)];
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => RecoveryAuthDialog(
        onSuccess: (user) {
          context.read<RoomProvider>().setUser(user);
          context.read<RoomProvider>().fetchRooms();
          CyberMessenger.show('ACCESS GRANTED: ${user.name}');
        },
      ),
    );
  }

  void _joinRoom(RoomModel room) {
    final roomProvider = context.read<RoomProvider>();
    if (roomProvider.currentUser == null) {
      _showAuthDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          room: room, 
          user: roomProvider.currentUser!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use watch here so the UI reacts to changes in RoomProvider or UserProvider
    final roomProvider = context.watch<RoomProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CyberAppBar(),
      body: Stack(
        children: [
          CustomPaint(
            painter: MatrixRainPainter(symbols: _matrixSymbols),
            size: Size.infinite,
          ),
          _buildScanningLine(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildHeader(roomProvider),
                Expanded(child: _buildRoomsSection(roomProvider)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildUserButton(currentUser, userProvider, roomProvider),
    );
  }

  Widget _buildUserButton(UserModel? user, UserProvider uProv, RoomProvider rProv) {
    if (user == null) {
      return FloatingActionButton(
        onPressed: _showAuthDialog,
        backgroundColor: Colors.black,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00ff00), width: 2),
          ),
          child: const Center(child: Icon(Icons.person_outline, color: Color(0xFF00ff00))),
        ),
      );
    }
    return UserDataDisplay(
      user: user,
      onLogout: () {
        uProv.logout();
        rProv.fetchRooms(); // Refresh rooms for guest view
      },
    );
  }

  Widget _buildHeader(RoomProvider prov) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Text(
          'ACTIVE ROOMS: ${prov.rooms.length}',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 4,
            color: const Color(0xFF00ff00).withOpacity(0.5 + _pulseController.value * 0.3),
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget _buildRoomsSection(RoomProvider prov) {
    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00ff00)));
    }
    if (prov.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CONNECTION ERROR', style: TextStyle(color: Color(0xFFFF00ff))),
            IconButton(onPressed: prov.fetchRooms, icon: const Icon(Icons.refresh, color: Color(0xFF00ff00)))
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchRooms(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: prov.rooms.length,
        itemBuilder: (context, index) => _buildRoomCard(prov.rooms[index]),
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final String imagepath = "${RoomService.imageurl}/${room.logoPath}";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: room.isPublic ? const Color(0xFF00ff00).withOpacity(0.3) : Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.7),
      ),
      child: ListTile(
        onTap: () => _joinRoom(room),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: room.isPublic ? const Color(0xFF00ff00) : Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(imagepath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
        title: Text(room.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(room.participantDisplay, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: Text(room.roomStatusIcon),
      ),
    );
  }

  Widget _buildScanningLine() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 4),
      tween: Tween(begin: 0, end: 1),
      onEnd: () => setState(() {}),
      builder: (context, value, child) {
        return Positioned(
          top: value * MediaQuery.of(context).size.height,
          left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF00ff00).withOpacity(0.5), Colors.transparent]),
            ),
          ),
        );
      },
    );
  }
}