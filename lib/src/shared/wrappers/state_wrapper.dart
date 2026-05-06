import '../../imports/imports.dart';
import '../../services/auth_repository_impl.dart';
import '../../controllers/auth/session_provider.dart';

class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>(
            create: (_) => SessionProvider(repository: AuthRepositoryImpl())),
      ],
      child: child,
    );
  }
}
