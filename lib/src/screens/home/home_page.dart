import 'package:cyberchat/src/imports/core_imports.dart';
import 'package:cyberchat/src/imports/packages_imports.dart';

import 'package:cyberchat/src/controllers/auth/session_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final session = context.watch<SessionProvider>();
    final user = session.user;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const AppTopBar(
        title: 'Home',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppIcon(
                icon: Icons.abc,
                size: 60,
                color: colorScheme.primary,
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                user?.name ?? user?.email ?? ('Welcome Home!'),
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  fontSize: 28,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                user != null && user.name != null
                    ? user.email
                    : ('You have successfully completed the onboarding process.'),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
