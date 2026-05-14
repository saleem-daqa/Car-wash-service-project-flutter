import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'company_cars_management_screen.dart';
import 'team_members_screen.dart';

class TeamsManagementScreen extends StatefulWidget {
  const TeamsManagementScreen({super.key});

  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen> {
  Future<List<dynamic>>? teamsFuture;
  Future<List<dynamic>>? carsFuture;

  @override
  void initState() {
    super.initState();
    loadTeams();
    loadCars();
  }

  void loadTeams() {
    setState(() {
      teamsFuture = fetchTeams();
    });
  }

  Future<List<dynamic>> fetchTeams() async {
    final response = await http.get(Uri.parse(ApiConfig.teamsListUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['teams'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> loadCars() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/company_cars_list.php'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['cars'] ?? [];
    }
    return [];
  }

  Future<void> deleteTeam(int teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text('Are you sure you want to delete this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/team_delete.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'team_id': teamId}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          loadTeams();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Could not delete'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void editTeam(Map<String, dynamic> team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditTeamScreen(team: team, onSaved: () => loadTeams()),
      ),
    );
  }

  void addTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTeamScreen(onSaved: () => loadTeams()),
      ),
    );
  }

  void viewTeamMembers(Map<String, dynamic> team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TeamMembersScreen(team: team, onUpdated: () => loadTeams()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams Management')),
      body: RefreshIndicator(
        onRefresh: () async {
          loadTeams();
          await teamsFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: teamsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final teams = snapshot.data ?? [];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: addTeam,
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Team'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CompanyCarsManagementScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions_car),
                        label: const Text('Cars'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: teams.isEmpty
                      ? const Center(child: Text('No teams available'))
                      : ListView.builder(
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.groups,
                                  color: AppTheme.primaryBlue,
                                ),
                                title: Text(
                                  team['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Car: ${team['car_plate'] ?? 'N/A'} - ${team['car_model'] ?? 'N/A'}',
                                    ),
                                    Text(
                                      'Members: ${team['member_count'] ?? 0}',
                                    ),
                                    Text(
                                      'Status: ${team['is_active'] == 1 ? 'Active' : 'Inactive'}',
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.people,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => viewTeamMembers(team),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      onPressed: () => editTeam(team),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          deleteTeam(team['team_id']),
                                    ),
                                  ],
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
    );
  }
}

class AddEditTeamScreen extends StatefulWidget {
  final Map<String, dynamic>? team;
  final VoidCallback onSaved;

  const AddEditTeamScreen({super.key, this.team, required this.onSaved});

  @override
  State<AddEditTeamScreen> createState() => _AddEditTeamScreenState();
}

class _AddEditTeamScreenState extends State<AddEditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _selectedCarId;
  bool _isActive = true;
  bool _isLoading = false;
  List<dynamic> _cars = [];

  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _nameController.text = widget.team!['name'] ?? '';
      _selectedCarId = widget.team!['company_car_id'];
      _isActive = (widget.team!['is_active'] ?? 1) == 1;
    }
    loadCars();
  }

  Future<void> loadCars() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/company_cars_list.php'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _cars = data['cars'] ?? [];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company car'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = {
        'name': _nameController.text.trim(),
        'company_car_id': _selectedCarId,
        'is_active': _isActive ? 1 : 0,
      };

      if (widget.team != null) {
        body['team_id'] = widget.team!['team_id'];
        final response = await http.put(
          Uri.parse(ApiConfig.teamUpdateUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (!mounted) return;
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Team updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
            widget.onSaved();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? 'Failed to update'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        final response = await http.post(
          Uri.parse(ApiConfig.teamCreateUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (!mounted) return;
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Team created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
            widget.onSaved();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? 'Failed to create'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team == null ? 'Add Team' : 'Edit Team'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedCarId,
                decoration: const InputDecoration(
                  labelText: 'Company Car',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: _cars.map((car) {
                  return DropdownMenuItem<int>(
                    value: car['company_car_id'],
                    child: Text('${car['plate_number']} - ${car['model']}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCarId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveTeam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.team == null ? 'Create Team' : 'Update Team',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
