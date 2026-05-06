import 'package:cyberchat/src/imports/core_imports.dart';
import 'package:cyberchat/src/imports/packages_imports.dart';

import 'package:cyberchat/src/controllers/auth/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthProvider p) => p.isLoading);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleSignup() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      

      context.read<AuthProvider>().signUp(
        context: context, 
        name: _nameController.text,
        email: _emailController.text, 
        password: _passwordController.text,
      );
    }

    return _SignupView(
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      obscurePassword: _obscurePassword,
      obscureConfirmPassword: _obscureConfirmPassword,
      isLoading: isLoading,
      onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
      onToggleConfirmObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
      onSignup: handleSignup,
      cs: cs,
      tt: tt,
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onToggleConfirmObscure,
    required this.onSignup,
    required this.cs,
    required this.tt,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirmObscure;
  final VoidCallback onSignup;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Create Account',
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Join us and start your journey',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: nameController,
                        enabled: !isLoading,
                        label: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: emailController,
                        enabled: !isLoading,
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
                      SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: passwordController,
                        enabled: !isLoading,
                        label: 'Password',
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: onToggleObscure,
                        ),
                         validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'Password is required';
                          }
                          if (v!.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: confirmPasswordController,
                        enabled: !isLoading,
                        label: 'Confirm Password',
                        obscureText: obscureConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: onToggleConfirmObscure,
                        ),
                         validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'Confirm password is required';
                          }
                          if (v != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Sign Up',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : onSignup,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.login);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
