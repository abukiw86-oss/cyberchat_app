
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/index.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/adapters.dart';
import 'models/user_model.dart';
import 'services/chache_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  
  // Register adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(RoomModelAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  
  // Open boxes
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<List>('roomsBox');
  await Hive.openBox<Map>('messagesBox');
  await Hive.openBox<String>('imagesBox');
  await Hive.openBox<DateTime>('timestampsBox');
  
  // Open additional boxes for RoomApiService
  await Hive.openBox<List>('participantsBox');
  await Hive.openBox<Map>('roomInfoBox');
  
  // Initialize cache service
  final cacheService = CacheService();
  await cacheService.ensureBoxesAreOpen();
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


