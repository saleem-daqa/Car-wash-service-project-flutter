import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/input_validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_text_field.dart';
import 'registerpart.dart';

class SignupPage extends StatefulWidget {
  final AuthService? authService;

  const SignupPage({super.key, this.authService});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  AuthService get _authService => widget.authService ?? AuthService();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final userId = await _authService.register(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Account created. Add your first vehicle to continue.',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationScreen(
            userId: userId,
            username: nameController.text.trim(),
            email: emailController.text.trim(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Could not create account. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: AppShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create account', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Set up your car wash account and add your first vehicle.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Full name',
                          hintText: 'Enter your name',
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.person_outline,
                          validator: InputValidators.fullName,
                          autofillHints: const [AutofillHints.name],
                        ),
                        AppTextField(
                          label: 'Email',
                          hintText: 'name@example.com',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline,
                          validator: InputValidators.email,
                          autofillHints: const [AutofillHints.email],
                        ),
                        AppTextField(
                          label: 'Phone number',
                          hintText: '0590000000',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s]'),
                            ),
                          ],
                          validator: InputValidators.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                        ),
                        AppTextField(
                          label: 'Password',
                          hintText: 'At least 6 characters',
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          validator: InputValidators.password,
                          autofillHints: const [AutofillHints.newPassword],
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
                        AppTextField(
                          label: 'Confirm password',
                          hintText: 'Repeat your password',
                          controller: confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: Icons.verified_user_outlined,
                          validator: (value) => InputValidators.confirmPassword(
                            value,
                            passwordController.text,
                          ),
                          autofillHints: const [AutofillHints.newPassword],
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Create account',
                          icon: Icons.person_add_alt_1,
                          isLoading: _loading,
                          onPressed: signup,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Log in'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 160,
              child: Image.asset('assets/background.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
