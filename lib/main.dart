import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';


Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await dotenv.load(fileName: '.env');
  
  await AppConfig.init();
  await HiveService.instance.init();

  runApp(
    const StateWrapper(
      child: App(),
    ),
  );
}