import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManageServicesTeamsScreen extends StatelessWidget {
  const ManageServicesTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services & Teams')),
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
