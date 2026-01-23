import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'loginscreen.dart';
import 'change_password_screen.dart';

class ManagerCreateTeamAccountScreen extends StatefulWidget {
  const ManagerCreateTeamAccountScreen({super.key});

  @override
  State<ManagerCreateTeamAccountScreen> createState() =>
      _ManagerCreateTeamAccountScreenState();
}

class _ManagerCreateTeamAccountScreenState
    extends State<ManagerCreateTeamAccountScreen> {
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  final _formKey = GlobalKey<FormState>();

  final _teamName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _teamName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backend not connected yet (Create Account).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team Account'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'change_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manager Action',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkBlue,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create login credentials for a team. The actual creation should be done securely via backend.',
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _teamName,
                      decoration: const InputDecoration(
                        labelText: 'Team name',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Required';
                        if (!s.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        final s = (v ?? '');
                        if (s.isEmpty) return 'Required';
                        if (s.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _createAccount,
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
