import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'loginscreen.dart';
import 'change_password_screen.dart';

class ManageServicesTeamsScreen extends StatelessWidget {
  const ManageServicesTeamsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services & Teams'),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 52,
                    color: AppTheme.primaryBlue.withOpacity(0.65),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Control Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Services, teams, and cars will appear here once data is connected.',
                    textAlign: TextAlign.center,
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
            child: ListTile(
              leading: const Icon(Icons.design_services_outlined,
                  color: AppTheme.primaryBlue),
              title: const Text('Services'),
              subtitle: const Text('No services loaded'),
              trailing: const Icon(Icons.lock_outline),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connect services data first.')),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading:
              const Icon(Icons.groups_outlined, color: AppTheme.primaryBlue),
              title: const Text('Teams'),
              subtitle: const Text('No teams loaded'),
              trailing: const Icon(Icons.lock_outline),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connect teams data first.')),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading:
              const Icon(Icons.directions_car, color: AppTheme.primaryBlue),
              title: const Text('Cars'),
              subtitle: const Text('No cars loaded'),
              trailing: const Icon(Icons.lock_outline),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connect cars data first.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
