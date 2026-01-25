import 'package:flutter/material.dart';
import '../widgets/section_card.dart';
import '../theme/app_theme.dart';
import 'manager_dashboard_screen.dart';
import 'manage_services_teams_screen.dart';
import 'manager_create_team_account_screen.dart';
import 'loginscreen.dart';
import 'change_password_screen.dart';

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

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
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false, // Remove all previous routes
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
        title: const Text('Manager Home'),
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
                    Icons.person_outline,
                    size: 52,
                    color: AppTheme.primaryBlue.withOpacity(0.65),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome, Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your car wash operations',
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

          const SizedBox(height: 16),
          SectionCard(
            number: 1,
            title: 'Dashboard',
            bullets: const [
              'View bookings & statistics',
              'Revenue overview',
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManagerDashboardScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          SectionCard(
            number: 2,
            title: 'Create Employee Account',
            bullets: const [
              'Create employee accounts',
              'Assign employees to teams',
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManagerCreateTeamAccountScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          SectionCard(
            number: 3,
            title: 'Services & Teams',
            bullets: const [
              'Add / edit services',
              'Assign teams & cars',
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageServicesTeamsScreen(),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}
