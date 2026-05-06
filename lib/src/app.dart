import 'package:cyberchat/src/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _buildMaterialApp(context);
    return current;
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp.router(
      title: 'cyberchat',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#080080'),
      darkTheme: buildDarkTheme(primaryColorHex: '#080080'),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) {
        Widget current = child!;
        current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}