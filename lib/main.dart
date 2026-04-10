import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Don't forget this import!
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screen/index.dart';
import 'models/user_model.dart';
import 'services/rooms_cache_service.dart';
import 'providers/room_chat_provider.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Setup Environment
  await dotenv.load(fileName: '.env');
  await SharedPreferences.getInstance();
  
  // 2. Setup Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path); 
  await Hive.openBox<UserModel>('userBox');
   
  final cacheService = RoomCacheService();
  await cacheService.ensureBoxesAreOpen();
   
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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