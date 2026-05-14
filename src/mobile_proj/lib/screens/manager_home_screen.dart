import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_feedback.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_action_card.dart';
import 'change_password_screen.dart';
import 'loginscreen.dart';
import 'manage_services_teams_screen.dart';
import 'manager_create_team_account_screen.dart';
import 'manager_dashboard_screen.dart';

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out of the manager dashboard?',
      confirmLabel: 'Log out',
      isDanger: true,
    );

    if (!confirmed || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account options',
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
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppShell(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 30,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, Manager', style: textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Track bookings, services, teams, and employee accounts.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DashboardActionCard(
              icon: Icons.insights_outlined,
              title: 'Operations dashboard',
              subtitle: 'View bookings, status activity, and revenue overview',
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
            DashboardActionCard(
              icon: Icons.badge_outlined,
              title: 'Create employee account',
              subtitle: 'Add team members and prepare them for assignments',
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
            DashboardActionCard(
              icon: Icons.design_services_outlined,
              title: 'Services and teams',
              subtitle: 'Manage wash services, work teams, and company cars',
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
      ),
    );
  }
}
