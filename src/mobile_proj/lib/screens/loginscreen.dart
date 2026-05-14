import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/input_validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_text_field.dart';
import 'customer_home_screen.dart';
import 'employee_home_screen.dart';
import 'manager_home_screen.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  final AuthService? authService;

  const LoginPage({super.key, this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  AuthService get _authService => widget.authService ?? AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (!_formKey.currentState!.validate()) {
      showAppSnackBar(
        context,
        message: 'Please fill in both fields',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', session.userId);

      if (!mounted) return;

      final destinationScreen = switch (session.role) {
        UserRole.manager => const ManagerHomeScreen(),
        UserRole.customer => const CustomerHomeScreen(),
        UserRole.employee => const EmployeeHomeScreen(),
        UserRole.unknown => null,
      };

      if (destinationScreen == null) {
        showAppSnackBar(context, message: 'Unknown user role', isError: true);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinationScreen),
      );
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Could not login. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: false,
      ),
      body: AppShell(
        maxWidth: 480,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_car_wash,
                  color: colorScheme.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              Text('Login', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Welcome back',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        autofillHints: const [AutofillHints.email],
                        validator: InputValidators.email,
                      ),
                      AppTextField(
                        label: 'Password',
                        obscureText: _obscurePassword,
                        controller: passwordController,
                        prefixIcon: Icons.lock_outline,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppButton(
                        label: 'Login',
                        icon: Icons.login,
                        isLoading: _isLoading,
                        onPressed: login,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text("Don't have an account?", style: textTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
                    child: const Text('Sign up'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/welcome.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
