
import 'package:cyberchat/widgets/appBar_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/background_matrix.dart';
import '../widgets/user_data_display.dart';
import 'dart:async';
import 'dart:math';
import '../models/rooms_model.dart';
import '../services/api_services/room_service.dart';
import '../services/api_services/auth_api.dart';
import '../screen/chat_screen.dart';
import '../models/user_model.dart';
import '../widgets/auth_widget.dart'; 
import '../widgets/handle_errors_in_scaffoldOfMessenger.dart';
import '../widgets/cached_network_image.dart';


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
  
  final RoomService _roomService = RoomService();
  List<RoomModel> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  UserModel? _currentUser;
  final AuthService _authService = AuthService();

  @override
void initState() {
    super.initState();
     _loadSavedUser();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    for (int i = 0; i < 30; i++) {
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
        setState(() {
          _isLoading = true;
        });
      }
    });
  }

Future<void> _loadSavedUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
      });
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
        CyberMessenger.show('Welcome ${user.name}!');
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
    if (true) {
      _navigateToRoom(room, _currentUser!);
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
    final rooms = await _roomService.fetchRooms(forceRefresh: true);

    if (mounted) {
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    }
  } catch (e) {
    print(e);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    print('Fetch Error: $_errorMessage');
  }
}

String _getRandomMatrixSymbol() {
    const String chars = '0101010101001001001001001001010101010101010101010101010101010010101';
    return chars[_random.nextInt(chars.length)];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matrixTimer.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: CyberAppBar(),
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
                const SizedBox(height: 30,),
                _buildHeader(),

                Expanded(
                  child: _buildRoomsSection(),
                ),
              ],
            ),
          ),
          _buildScanningLine(),
        ],
      ),
      floatingActionButton: _buildUserButton()
    );
  }

Widget _buildUserButton() {
  if (_currentUser == null) {
    return FloatingActionButton(
      onPressed: _showAuthDialog,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00ff00),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(
          Icons.person_outline,
          color: Color(0xFF00ff00),
        ),
      ),
    );
  }
  return UserDataDisplay(
    user: _currentUser!,
    onLogout: () {
      setState(() {
        _currentUser = null;
      });
      _fetchRooms();
      Navigator.of(context);
    },
  );
}

Widget _buildHeader() {
  return 
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
            ElevatedButton(onPressed: _fetchRooms, child: Icon(Icons.refresh))
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
            child: RefreshIndicator(
            onRefresh: () => _fetchRooms(),
            color: const Color(0xFF00ff00),
            backgroundColor: Colors.black,
           child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final room = _rooms[index];
              return _buildRoomCard(room);
            },
          ),
        ),
        )
      ],
    );
  }

Widget _buildRoomCard(RoomModel room) {
  final String imagepath = "${RoomService.imageurl}/${room.logoPath}";
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
                      imagepath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return CachedNetworkImageWidget(
                          imageUrl: imagepath,
                          roomname: room.code,
                          isprofile: false,
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
                        ],
                      ),
                      const SizedBox(height: 4),
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

