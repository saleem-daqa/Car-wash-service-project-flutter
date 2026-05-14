import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/input_validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  final AuthService? authService;

  const ChangePasswordScreen({super.key, this.authService});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  AuthService get _authService => widget.authService ?? AuthService();

  Future<bool> _verifyCurrentPassword(String password) async {
    if (password.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      if (userId == 0) {
        return false;
      }

      return _authService.verifyPassword(userId: userId, password: password);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    if (!mounted) return;

    if (userId == 0) {
      showAppSnackBar(
        context,
        message: 'Please log in before changing your password.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isCurrentPasswordValid = await _verifyCurrentPassword(
        currentPasswordController.text,
      );

      if (!mounted) return;
      if (!isCurrentPasswordValid) {
        showAppSnackBar(
          context,
          message: 'Current password is incorrect.',
          isError: true,
        );
        return;
      }

      await _authService.changePassword(
        userId: userId,
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;

      showAppSnackBar(context, message: 'Password changed successfully.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Could not change password. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: AppShell(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Protect your account', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Use a strong password that is different from your old one.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Current password',
                        hintText: 'Enter current password',
                        controller: currentPasswordController,
                        obscureText: _obscureCurrent,
                        prefixIcon: Icons.lock_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          tooltip: _obscureCurrent
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrent = !_obscureCurrent;
                            });
                          },
                        ),
                      ),
                      AppTextField(
                        label: 'New password',
                        hintText: 'At least 6 characters',
                        controller: newPasswordController,
                        obscureText: _obscureNew,
                        prefixIcon: Icons.password_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter new password';
                          }
                          return InputValidators.password(value);
                        },
                        suffixIcon: IconButton(
                          tooltip: _obscureNew
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                      ),
                      AppTextField(
                        label: 'Confirm new password',
                        hintText: 'Repeat new password',
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirm,
                        prefixIcon: Icons.verified_user_outlined,
                        validator: (value) {
                          return InputValidators.confirmPassword(
                            value,
                            newPasswordController.text,
                          );
                        },
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirm
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Change password',
                        icon: Icons.save_outlined,
                        isLoading: _isLoading,
                        onPressed: _changePassword,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
