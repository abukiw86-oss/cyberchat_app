import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';

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
  }

  String _getRandomMatrixSymbol() {
    const String chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';
    return chars[_random.nextInt(chars.length)];
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _pulseController.dispose();
    _matrixTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Matrix rain background
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
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

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
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
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
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
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
                        'ENTER THE MATRIX',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 4,
                          color: const Color(0xFF00ff00).withOpacity(0.5 + _pulseController.value * 0.3),
                          fontWeight: FontWeight.w300,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Cyberpunk decorative elements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00ff00), Color(0xFF00ffff)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
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

                  const SizedBox(height: 60),

                  // Main action buttons
                  _buildCyberButton(
                    label: 'ENTER CHAT',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF00ff00),
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  _buildCyberButton(
                    label: 'JOIN ROOM',
                    icon: Icons.group_add_outlined,
                    color: const Color(0xFF00ffff),
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  _buildCyberButton(
                    label: 'SCAN NETWORK',
                    icon: Icons.scanner_outlined,
                    color: const Color(0xFFFF00ff),
                    onTap: () {},
                  ),

                  const Spacer(),

                  // Terminal-style status bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00ff00).withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00ff00),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00ff00).withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'SYSTEM ONLINE',
                              style: TextStyle(
                                color: Color(0xFF00ff00),
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'USERS: ${_random.nextInt(9000) + 1000}',
                          style: const TextStyle(
                            color: Color(0xFF00ffff),
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Scanning line effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 3),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 800),
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
                // Restart animation
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.3),
          highlightColor: color.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
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
    final paint = Paint()
      ..color = const Color(0xFF00ff00).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: const Color(0xFF00ff00),
      fontSize: 20,
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
          color: const Color(0xFF00ff00).withOpacity(0.3 + Random().nextDouble() * 0.5),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, symbol.position);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}