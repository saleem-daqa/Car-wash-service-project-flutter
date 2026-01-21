import 'package:flutter/material.dart';
import '../widgets/section_card.dart';

import 'employee_home_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manage_services_teams_screen.dart';
import 'manager_create_team_account_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee & Manager'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            number: 1,
            title: 'Employee Home',
            bullets: const [
              'Assigned jobs',
              'Start / finish washing',
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmployeeHomeScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          SectionCard(
            number: 2,
            title: 'Manager Dashboard',
            bullets: const [
              'View bookings',
              'Statistics & overview',
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
            number: 3,
            title: 'Create Team Accounts',
            bullets: const [
              'Create email & password for teams',
              'Managed by the manager only',
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

          // 4) Services & Teams
          SectionCard(
            number: 4,
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
