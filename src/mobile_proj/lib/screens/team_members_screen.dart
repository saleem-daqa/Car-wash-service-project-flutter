import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TeamMembersScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  final VoidCallback onUpdated;

  const TeamMembersScreen({
    super.key,
    required this.team,
    required this.onUpdated,
  });

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  Future<List<dynamic>>? membersFuture;
  Future<List<dynamic>>? availableEmployeesFuture;

  @override
  void initState() {
    super.initState();
    loadMembers();
    loadAvailableEmployees();
  }

  void loadMembers() {
    setState(() {
      membersFuture = fetchMembers();
    });
  }

  Future<List<dynamic>> fetchMembers() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/team_members_list.php?team_id=${widget.team['team_id']}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['members'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> loadAvailableEmployees() async {
    final response = await http.get(Uri.parse(ApiConfig.employeesListUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final allEmployees = data['employees'] ?? [];
      
      final membersResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/team_members_list.php'));
      if (membersResponse.statusCode == 200) {
        final membersData = json.decode(membersResponse.body);
        final assignedIds = (membersData['members'] ?? []).map((m) => m['employee_id']).toSet();
        return allEmployees.where((e) => !assignedIds.contains(e['user_id'])).toList();
      }
      return allEmployees;
    }
    return [];
  }

  Future<void> removeMember(int employeeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: const Text('Are you sure you want to remove this employee from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/team_members_remove.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'employee_id': employeeId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee removed from team'), backgroundColor: Colors.green),
          );
          loadMembers();
          loadAvailableEmployees();
          widget.onUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to remove'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> addEmployee(int employeeId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/team_members_add.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'team_id': widget.team['team_id'],
          'employee_id': employeeId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee added to team'), backgroundColor: Colors.green),
          );
          loadMembers();
          loadAvailableEmployees();
          widget.onUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to add'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team: ${widget.team['name'] ?? ''}'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Members',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<dynamic>>(
                    future: membersFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Text('$count member${count != 1 ? 's' : ''} in this team');
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                loadMembers();
                await membersFuture;
              },
              child: FutureBuilder<List<dynamic>>(
                future: membersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = snapshot.data ?? [];

                  if (members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No members in this team'),
                          const SizedBox(height: 16),
                          FutureBuilder<List<dynamic>>(
                            future: availableEmployeesFuture,
                            builder: (context, empSnapshot) {
                              final available = empSnapshot.data ?? [];
                              if (available.isEmpty) {
                                return const Text('No available employees');
                              }
                              return ElevatedButton.icon(
                                onPressed: () => _showAddEmployeeDialog(available),
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Employee'),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FutureBuilder<List<dynamic>>(
                          future: availableEmployeesFuture,
                          builder: (context, empSnapshot) {
                            final available = empSnapshot.data ?? [];
                            if (available.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ElevatedButton.icon(
                              onPressed: () => _showAddEmployeeDialog(available),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Employee to Team'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: AppTheme.primaryBlue),
                                title: Text(member['full_name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${member['email'] ?? ''}'),
                                    Text('Phone: ${member['phone'] ?? ''}'),
                                    Text('Status: ${member['is_active'] == 1 ? 'Active' : 'Inactive'}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => removeMember(member['employee_id']),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog(List<dynamic> availableEmployees) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee to Team'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableEmployees.length,
            itemBuilder: (context, index) {
              final employee = availableEmployees[index];
              return ListTile(
                title: Text(employee['full_name'] ?? 'Unknown'),
                subtitle: Text(employee['email'] ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  addEmployee(employee['user_id']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
