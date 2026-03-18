import 'package:flutter/material.dart';

class CyberMessenger {
  static void show(String message, {bool isError = false, Duration? duration}) {
    final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
      final state = messengerKey.currentState;
    if (state == null) return;
    state.hideCurrentSnackBar();

    state.showSnackBar(
      SnackBar(
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D), 
            border: Border.all(
              color: isError ? Colors.redAccent : const Color(0xFF00ff00),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.redAccent : const Color(0xFF00ff00)).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.bolt : Icons.terminal,
                color: isError ? Colors.redAccent : const Color(0xFF00ff00),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.toUpperCase(),
                  style: TextStyle(
                    color: isError ? Colors.redAccent : const Color(0xFF00ff00),
                    fontFamily: 'Courier',
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
