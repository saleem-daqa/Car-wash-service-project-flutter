import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'loginscreen.dart';
import 'change_password_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'services_management_screen.dart';
import 'teams_management_screen.dart';
import 'company_cars_management_screen.dart';

class ManageServicesTeamsScreen extends StatefulWidget {
  const ManageServicesTeamsScreen({super.key});

  @override
  State<ManageServicesTeamsScreen> createState() => _ManageServicesTeamsScreenState();
}

class _ManageServicesTeamsScreenState extends State<ManageServicesTeamsScreen> {
  Future<List<dynamic>>? servicesFuture;
  Future<List<dynamic>>? teamsFuture;

  @override
  void initState() {
    super.initState();
    servicesFuture = loadServices();
    teamsFuture = loadTeams();
  }

  Future<List<dynamic>> loadServices() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/services_list_all.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['services'] ?? [];
      } else if (data['ok'] == true && data['data'] != null) {
        return data['data']['services'] ?? [];
      }
    }
    return [];
  }

  Future<List<dynamic>> loadTeams() async {
    final response = await http.get(Uri.parse(ApiConfig.teamsListUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['teams'] ?? [];
    }
    return [];
  }

  void logout(BuildContext context) {
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
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
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
                logout(context);
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
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            servicesFuture = loadServices();
            teamsFuture = loadTeams();
          });
          return Future.wait([servicesFuture!, teamsFuture!]);
        },
        child: ListView(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.design_services_outlined, color: AppTheme.primaryBlue),
                title: const Text('Services'),
                subtitle: FutureBuilder<List<dynamic>>(
                  future: servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    final services = snapshot.data ?? [];
                    return Text('${services.length} service${services.length != 1 ? 's' : ''} available');
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServicesManagementScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups_outlined, color: AppTheme.primaryBlue),
                title: const Text('Teams'),
                subtitle: FutureBuilder<List<dynamic>>(
                  future: teamsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    final teams = snapshot.data ?? [];
                    return Text('${teams.length} team${teams.length != 1 ? 's' : ''} available');
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamsManagementScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: AppTheme.primaryBlue),
                title: const Text('Cars'),
                subtitle: const Text('Company cars management'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CompanyCarsManagementScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
