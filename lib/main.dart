// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'models/rooms_model.dart';
import 'services/room_services.dart';

void main() {
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
          surface: const Color(0xFF1a1a1a),
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
  
  // Room service and data
  final RoomService _roomService = RoomService();
  List<RoomModel> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize matrix symbols
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

    // Update matrix symbols periodically
    _matrixTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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
    });

    // Fetch rooms
    _fetchRooms();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchRooms();
    });
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await _roomService.fetchRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print(_errorMessage);
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

          // Gradient overlay for better readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header Section
                _buildHeader(),

                // Rooms Section
                Expanded(
                  child: _buildRoomsSection(),
                ),

                // Action Buttons
                _buildActionButtons(),

                // Status Bar
                _buildStatusBar(),
              ],
            ),
          ),

          // Scanning line effect
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

          // Animated glitch logo
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
                    // Glitch layers
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

          // Subtitle with pulse effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Text(
                'ACTIVE ROOMS: ${_rooms.length}',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 4,
                  color: const Color(0xFF00ff00).withOpacity(0.5 + _pulseController.value * 0.3),
                  fontWeight: FontWeight.w300,
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Cyberpunk decorative elements
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
            Container(
              width: 50,
              height: 50,
              child: const CircularProgressIndicator(
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
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
              : const Color(0xFFFF00ff).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to room
            // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(room: room)));
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: room.isPublic 
              ? const Color(0xFF00ff00).withOpacity(0.2)
              : const Color(0xFFFF00ff).withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Room Logo/Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: room.isPublic 
                          ? const Color(0xFF00ff00)
                          : const Color(0xFFFF00ff),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                  ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            "assets/default_logo.jpg",
                            fit: BoxFit.cover,
                          ),
                        )
                ),
                const SizedBox(width: 12),
                // Room Details
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
                            style: TextStyle(
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
                            style: TextStyle(
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
                              : const Color(0xFFFF00ff).withOpacity(0.7),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enter button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: room.isPublic 
                          ? const Color(0xFF00ff00)
                          : const Color(0xFFFF00ff),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ENTER',
                    style: TextStyle(
                      color: room.isPublic 
                          ? const Color(0xFF00ff00)
                          : const Color(0xFFFF00ff),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
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
              label: 'PUBLIC',
              icon: Icons.public,
              color: const Color(0xFF00ff00),
              onTap: () {
                // Filter public rooms
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCyberSmallButton(
              label: 'PRIVATE',
              icon: Icons.lock_outline,
              color: const Color(0xFFFF00ff),
              onTap: () {
                // Filter private rooms
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCyberSmallButton(
              label: 'CREATE',
              icon: Icons.add,
              color: const Color(0xFF00ffff),
              onTap: () {
                // Navigate to create room
              },
            ),
          ),
        ],
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
                'SYSTEM ONLINE',
                style: TextStyle(
                  color: const Color(0xFF00ff00),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Text(
            'ROOMS: ${_rooms.length}',
            style: const TextStyle(
              color: Color(0xFF00ffff),
              fontSize: 10,
              letterSpacing: 1,
            ),
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
          setState(() {});
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
    final textStyle = TextStyle(
      color: const Color(0xFF00ff00),
      fontSize: 16,
      fontFamily: 'monospace',
    );

    final textSpan = TextSpan(text: '0', style: textStyle);
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