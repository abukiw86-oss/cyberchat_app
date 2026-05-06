import 'package:cyberchat/src/imports/core_imports.dart';
import 'package:cyberchat/src/imports/packages_imports.dart';

import 'package:cyberchat/src/controllers/auth/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthProvider p) => p.isLoading);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleForgotPassword() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      

      context.read<AuthProvider>().forgotPassword(
        context: context, 
        email: _emailController.text,
      );
    }

    return _ForgotPasswordView(
      formKey: _formKey,
      emailController: _emailController,
      isLoading: isLoading,
      onForgotPassword: handleForgotPassword,
      cs: cs,
      tt: tt,
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onForgotPassword,
    required this.cs,
    required this.tt,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onForgotPassword;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Reset Password',
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter your email to receive a reset link',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        label: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'Email is required';
                          }
                          if (!AppUtils.isValidEmail(v!)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Send Reset Link',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : onForgotPassword,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Login',
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
