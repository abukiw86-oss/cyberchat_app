
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/index.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/adapters.dart';
import 'models/user_model.dart';
import 'services/rooms_cache_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(RoomModelAdapter()); 
  
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<List>('roomsBox');
  await Hive.openBox<String>('imagesBox');
  await Hive.openBox<DateTime>('timestampsBox');
  
  await Hive.openBox<List>('participantsBox');
  await Hive.openBox<Map>('roomInfoBox');
  
  final cacheService = RoomCacheService();
  await cacheService.ensureBoxesAreOpen();
  await dotenv.load(fileName:'.env');
   
  runApp(CyberChatApp());
}

class CyberChatApp extends StatelessWidget {
   CyberChatApp({super.key});
  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

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


