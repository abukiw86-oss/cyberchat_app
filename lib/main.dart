import 'package:cyberchat/providers/profile_editing_provider.dart';
import 'package:cyberchat/providers/room_provider.dart';
import 'package:cyberchat/providers/userProvider.dart';
import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart';   
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screen/index.dart';  
import 'providers/room_chat_provider.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   
  await dotenv.load(fileName: '.env'); 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const CyberChatApp(),  
    ),
  );
}

class CyberChatApp extends StatelessWidget {
  const CyberChatApp({super.key}); 

  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberChat',
      scaffoldMessengerKey: messengerKey,
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