import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'loginscreen.dart';
import 'change_password_screen.dart';
import 'manager_bookings_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  Future<Map<String, dynamic>>? statsFuture;
  Future<List<dynamic>>? activitiesFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = loadStats();
    activitiesFuture = loadActivities();
  }

  Future<Map<String, dynamic>> loadStats() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.managerStatsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          return {};
        }
        return data;
      }
    } catch (e) {
      return {};
    }
    return {};
  }

  Future<List<dynamic>> loadActivities() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.managerRecentActivitiesUrl),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          return [];
        }
        return data['activities'] ?? [];
      }
    } catch (e) {
      return [];
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
        title: const Text('Manager Dashboard'),
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
            statsFuture = loadStats();
            activitiesFuture = loadActivities();
          });
          return Future.wait([statsFuture!, activitiesFuture!]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final stats = snapshot.data ?? {};
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dashboard_outlined,
                          size: 52,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.65),
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
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildStatItem(
                              'Total Bookings',
                              '${stats['total_bookings'] ?? 0}',
                            ),
                            _buildStatItem(
                              'Active Services',
                              '${stats['active_services'] ?? 0}',
                            ),
                            _buildStatItem(
                              'Employees',
                              '${stats['active_employees'] ?? 0}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (stats['total_revenue'] != null)
                          Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.attach_money,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Text(
                                        '${(double.tryParse((stats['total_revenue'] ?? 0).toString()) ?? 0.0).toStringAsFixed(2)} ₪',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const Text(
                                        'Total Revenue',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (stats['avg_rating'] != null &&
                            (double.tryParse(
                                      (stats['avg_rating'] ?? 0).toString(),
                                    ) ??
                                    0.0) >
                                0)
                          Card(
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(double.tryParse((stats['avg_rating'] ?? 0).toString()) ?? 0.0).toStringAsFixed(1)} / 5.0',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${stats['rating_count'] ?? 0} reviews)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.event_note,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('View All Bookings'),
                subtitle: const Text('See bookings with employee & team info'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManagerBookingsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.bar_chart,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('Statistics & Revenue'),
                subtitle: FutureBuilder<Map<String, dynamic>>(
                  future: statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final stats = snapshot.data ?? {};
                      final avgRating = stats['avg_rating'] ?? 0.0;
                      return Text(
                        'Avg Rating: ${avgRating.toStringAsFixed(1)}',
                      );
                    }
                    return const Text('Loading...');
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<dynamic>>(
                      future: activitiesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final activities = snapshot.data ?? [];
                        if (activities.isEmpty) {
                          return const Text('No recent activities');
                        }
                        return Column(
                          children: activities.take(5).map((activity) {
                            return ListTile(
                              leading: Icon(
                                activity['type'] == 'booking'
                                    ? Icons.event_note
                                    : activity['type'] == 'wallet'
                                    ? Icons.account_balance_wallet
                                    : Icons.feedback,
                                color: AppTheme.primaryBlue,
                              ),
                              title: Text(activity['title'] ?? ''),
                              subtitle: Text(activity['subtitle'] ?? ''),
                              trailing: Text(
                                _formatTime(activity['time'] ?? ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final date = DateTime.parse(timeStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return timeStr;
    }
  }
}
