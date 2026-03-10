// lib/main.dart
import 'package:cyberchat/services/cookie_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'models/rooms_model.dart';
import 'services/get_rooms.dart';
import 'services/auth.dart';
import 'screen/chat_screen.dart';
import 'models/user_model.dart';
import 'widgets/auth_widget.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/create_room.dart';
import 'widgets/input_room_password.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const CyberChatApp());
}

class CyberChatApp extends StatelessWidget {
  const CyberChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberChat',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF00ff00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00ff00),
          secondary: Color(0xFF00ffff),
          surface: Color(0xFF1a1a1a),
        ),
      ),
      home: const CyberChatHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CyberChatHomePage extends StatefulWidget {
  const CyberChatHomePage({super.key});

  @override
  State<CyberChatHomePage> createState() => _CyberChatHomePageState();
}

class _CyberChatHomePageState extends State<CyberChatHomePage> with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _pulseController;
  final Random _random = Random();
  late Timer _matrixTimer;
  final List<MatrixSymbol> _matrixSymbols = [];
  
  final RoomService _roomService = RoomService();
  List<RoomModel> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  final CookieService _cookieService = CookieService();
  
  UserModel? _currentUser;
  final String _roomCode = '';
  final String _roomType = 'public';

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    for (int i = 0; i < 50; i++) {
      _matrixSymbols.add(
        MatrixSymbol(
          position: Offset(
            _random.nextDouble() * 400,
            _random.nextDouble() * 800,
          ),
          symbol: _getRandomMatrixSymbol(),
        ),
      );
    }
    _matrixTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          for (var symbol in _matrixSymbols) {
            if (_random.nextDouble() > 0.7) {
              symbol.symbol = _getRandomMatrixSymbol();
            }
            symbol.position = Offset(
              symbol.position.dx,
              symbol.position.dy + _random.nextDouble() * 5,
            );
            if (symbol.position.dy > 800) {
              symbol.position = Offset(symbol.position.dx, 0);
            }
          }
        });
      }
    });
    _fetchRooms();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchRooms();
      }
    });
  }

Future<void> _logout() async {
  try {
    setState(() {
      _isLoading = true;
    });
    final authService = AuthService();
    await authService.logout();
    await _cookieService.clearCookies();
    
    setState(() {
      _currentUser = null;
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Color(0xFF00ff00),
        ),
      );
      _fetchRooms();
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error!'),
          backgroundColor: const Color.fromARGB(255, 255, 47, 0),
        ),
      );
    }
  }
}

void _showCreateRoomDialog() {
  if (_currentUser == null) {
    _showAuthDialog();
    return;
  }

  showDialog(
    context: context,
    builder: (context) => CreateRoomDialog(
      user: _currentUser!,
      onRoomCreated: (result) {
        final roomData = result['room'];
        final isCreator = result['is_creator'] ?? true;
        final inviteCode = result['invite_code'];
        
        final newRoom = RoomModel(
          code: roomData['code'] ?? _roomCode,
          participants: 1,
          lastActive: DateTime.now().toIso8601String(),
          nickname: _currentUser!.name,
          status: roomData['status'] ?? _roomType,
          logoPath: roomData['logo_path'] ?? '',
          userLimits: roomData['user_limits'] ?? 0,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room "$_roomCode" created successfully!',
                  style: const TextStyle(color: Colors.black),
                ),
                if (inviteCode != null && inviteCode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Invite Code: $inviteCode',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: const Color(0xFF00ffff),
            duration: const Duration(seconds: 2),
          ),
        );
        _fetchRooms();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToRoom(newRoom, _currentUser!);
          }
        });
      },
    ),
  );
}

Future<void> _checkExistingSession() async {
    final authService = AuthService();
    try {
      final user = await authService.checkSession();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Session check error: $e');
    }
  }

void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => RecoveryAuthDialog(
        onSuccess: (user) {
          setState(() {
            _currentUser = user;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${user.name}!'),
              backgroundColor: const Color(0xFF00ff00),
            ),
            
          );
          _fetchRooms();
        },
      ),
    );
  }


Future<void> _joinRoom(RoomModel room) async {
  if (_currentUser == null) {
    _showAuthDialog();
    return;
  }

  setState(() => _isLoading = true);

  try {
    final result = await _roomService.joinRoom(
      roomCode: room.code,
      nickname: _currentUser!.name,
    );

    print('Join room response: $result'); 

    if (result['success'] == true) {
      _navigateToRoom(room, _currentUser!);

    } else {
      print(result['message'] ?? 'Failed to join room');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

void _navigateToRoom(RoomModel room, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(room: room, user: user),
      ),
    );
  }

void _showJoinRoomDialog(RoomModel room) {
    _joinRoom(room);
  }

Future<void> _fetchRooms() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await _roomService.fetchRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('hh $_errorMessage');
    }
  }

String _getRandomMatrixSymbol() {
    const String chars = '0101010101002001001001001001010101010101010101010101010101010010101';
    return chars[_random.nextInt(chars.length)];
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _pulseController.dispose();
    _matrixTimer.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: MatrixRainPainter(symbols: _matrixSymbols),
            size: Size.infinite,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: _buildRoomsSection(),
                ),
                _buildActionButtons(),
                _buildStatusBar(),
              ],
            ),
          ),
          _buildScanningLine(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _glitchController.value * 2 * sin(DateTime.now().millisecondsSinceEpoch / 100),
                  0,
                ),
                child: Stack(
                  children: [
                    Text(
                      'CYBERCHAT',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = const Color(0xFF00ffff).withOpacity(0.5),
                        shadows: [
                          Shadow(
                            color: const Color(0xFF00ff00).withOpacity(0.5),
                            offset: Offset(-2 * _glitchController.value, 2 * _glitchController.value),
                            blurRadius: 4,
                          ),
                          Shadow(
                            color: const Color(0xFFFF00ff).withOpacity(0.5),
                            offset: Offset(2 * _glitchController.value, -2 * _glitchController.value),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'CYBERCHAT',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: const Color(0xFF00ff00),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Text(
                'ACTIVE ROOMS: ${_rooms.length}',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 4,
                  color: const Color(0xFF00ff00).withOpacity(0.5 + _pulseController.value * 0.3),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00ff00), Color(0xFF00ffff)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF00ff00),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'v2.0',
                  style: TextStyle(
                    color: Color(0xFF00ff00),
                    fontSize: 10,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00ffff), Color(0xFF00ff00)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsSection() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ff00)),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SCANNING NETWORK...',
              style: TextStyle(
                color: const Color(0xFF00ff00).withOpacity(0.7),
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: const Color(0xFFFF00ff),
              size: 50,
            ),
            const SizedBox(height: 20),
            Text(
              'CONNECTION ERROR',
              style: TextStyle(
                color: const Color(0xFFFF00ff),
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildCyberSmallButton(
              label: 'RETRY',
              icon: Icons.refresh,
              color: const Color(0xFF00ffff),
              onTap: _fetchRooms,
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.radio_button_unchecked,
              color: const Color(0xFF00ff00).withOpacity(0.3),
              size: 50,
            ),
            const SizedBox(height: 20),
            Text(
              'NO ROOMS FOUND',
              style: TextStyle(
                color: const Color(0xFF00ff00).withOpacity(0.5),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROOM LIST',
                style: TextStyle(
                  color: const Color(0xFF00ffff),
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${_rooms.length} ACTIVE',
                style: TextStyle(
                  color: const Color(0xFF00ff00).withOpacity(0.7),
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final room = _rooms[index];
              return _buildRoomCard(room);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: room.isPublic 
              ? const Color(0xFF00ff00).withOpacity(0.3)
              : const Color.fromARGB(255, 196, 0, 0).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJoinRoomDialog(room),
          borderRadius: BorderRadius.circular(8),
          splashColor: room.isPublic 
              ? const Color(0xFF00ff00).withOpacity(0.2)
              : const Color.fromARGB(255, 194, 0, 0).withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: room.isPublic 
                          ? const Color(0xFF00ff00)
                          : const Color.fromARGB(255, 255, 0, 0),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      "https://astufindit.x10.mx/cyberchat/${room.logoPath}",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            room.code.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: room.isPublic 
                                  ? const Color(0xFF00ff00)
                                  : const Color.fromARGB(255, 213, 3, 3),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            room.roomStatusIcon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              room.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: const Color(0xFF00ffff),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.participantDisplay,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            color: const Color(0xFF00ffff),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(room.lastActive),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Host: ${room.nickname}',
                        style: TextStyle(
                          color: room.isPublic 
                              ? const Color(0xFF00ff00).withOpacity(0.7)
                              : const Color.fromARGB(255, 255, 0, 0).withOpacity(0.7),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString.replaceAll(' ', 'T'));
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
        Expanded(
            child: _buildCyberSmallButton(
              label: 'CREATE',
              icon: Icons.add,
              color: const Color(0xFF00ffff),
              onTap: _showCreateRoomDialog,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: _fetchRooms, child: Icon(Icons.refresh)),
          const SizedBox(width: 10),
          if (_currentUser != null) 
              Expanded(
                child: _buildCyberSmallButton(
                  label: 'LOGOUT',
                  icon: Icons.logout,
                  color: const Color.fromARGB(255, 255, 47, 0),
                  onTap: _logout,
                ),
              ),
          if (_currentUser == null) 
                  Expanded(
                    child: _buildCyberSmallButton(
                      label: 'START',
                      icon: Icons.login,
                      color: const Color.fromARGB(255, 44, 31, 225),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => RecoveryAuthDialog(
                            onSuccess: (user) {
                              setState(() {
                                _currentUser = user;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Welcome ${user.name}!'),
                                  backgroundColor: const Color(0xFF00ff00),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
       
        ]
      ),
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

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00ff00).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(6),
        color: Colors.black.withOpacity(0.7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF00ff00),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ff00).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currentUser != null 
                    ? 'USER: ${_currentUser!.name}' 
                    : 'GUEST MODE',
                style: TextStyle(
                  color: _currentUser != null 
                      ? const Color(0xFF00ffff)
                      : const Color(0xFF00ff00),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'ROOMS: ${_rooms.length}',
                style: const TextStyle(
                  color: Color(0xFF00ffff),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              if (_currentUser == null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showAuthDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00ff00)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'LOGIN',
                      style: TextStyle(
                        color: Color(0xFF00ff00),
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningLine() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 3),
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value * MediaQuery.of(context).size.height),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF00ff00).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
        onEnd: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}

class MatrixSymbol {
  Offset position;
  String symbol;

  MatrixSymbol({required this.position, required this.symbol});
}

class MatrixRainPainter extends CustomPainter {
  final List<MatrixSymbol> symbols;

  MatrixRainPainter({required this.symbols});

  @override
  void paint(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Color(0xFF00ff00),
      fontSize: 16,
      fontFamily: 'monospace',
    );

    const textSpan = TextSpan(text: '0', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    for (var symbol in symbols) {
      textPainter.text = TextSpan(
        text: symbol.symbol,
        style: textStyle.copyWith(
          color: const Color(0xFF00ff00).withOpacity(0.1 + Random().nextDouble() * 0.3),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, symbol.position);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}