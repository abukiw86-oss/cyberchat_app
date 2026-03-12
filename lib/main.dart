
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/index.dart';

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


