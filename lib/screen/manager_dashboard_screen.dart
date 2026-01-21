import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 52,
                    color: AppTheme.primaryBlue.withOpacity(0.65),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Statistics and bookings will be displayed here once data is connected.',
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
              leading: const Icon(Icons.event_note,
                  color: AppTheme.primaryBlue),
              title: const Text('Bookings'),
              subtitle: const Text('No data available'),
              trailing: const Icon(Icons.lock_outline),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading:
              const Icon(Icons.bar_chart, color: AppTheme.primaryBlue),
              title: const Text('Statistics & Revenue'),
              subtitle: const Text('Awaiting data connection'),
              trailing: const Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
    );
  }
}
