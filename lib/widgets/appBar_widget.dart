import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:math';
import '../services/internet_cheker.dart';
class CyberAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CyberAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(40); 

  @override
  State<CyberAppBar> createState() => _CyberAppBarState();
}

class _CyberAppBarState extends State<CyberAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: StreamBuilder<InternetStatus>(
        stream: NetworkService().onStatusChange,
        builder: (context, snapshot) {
          final status = snapshot.data;
          String headerText = 'CYBERCHAT';
          Color neonColor = const Color(0xFF00ff00);
          double fontSize = 24; 

          if (status == InternetStatus.disconnected) {
            headerText = 'WAITING FOR NETWORK...';  
            neonColor = Colors.redAccent;
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            headerText = 'UPDATING...';
            neonColor = const Color(0xFF00ffff);
          }

          return AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _glitchController.value * 1.5 * sin(DateTime.now().millisecondsSinceEpoch / 50),
                  0,
                ),
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Text(
                      headerText,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 1
                          ..color = neonColor.withOpacity(0.5),
                      ),
                    ), 
                    Text(
                      headerText,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: neonColor,
                        shadows: [
                          Shadow(color: neonColor, blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
