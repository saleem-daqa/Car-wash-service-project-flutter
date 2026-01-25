import 'package:flutter/material.dart';
import '../models/job.dart';
import 'job_details_screen.dart';
import 'loginscreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  Future<List<Job>>? jobsFuture;

  @override
  void initState() {
    super.initState();
    jobsFuture = fetchJobs();
  }

  Future<List<Job>> fetchJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getInt('user_id') ?? 0;

    if (employeeId == 0) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_all_bookings_for_employees.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final allBookings = data['data'] as List;
          final jobsList = allBookings.map((jobData) {
            return Job.fromJson(jobData);
          }).toList();
          return jobsList;
        }
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  void logout() {
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

  Color getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
    }
  }

  String getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Job>>(
        future: jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          } else {
            final jobs = snapshot.data ?? [];
            if (jobs.isEmpty) {
              return const Center(child: Text('No jobs assigned yet'));
            }
            return RefreshIndicator(
              onRefresh: () {
                setState(() {
                  jobsFuture = fetchJobs();
                });
                return jobsFuture!;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 3,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getStatusColor(job.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_car_wash,
                          color: getStatusColor(job.status),
                          size: 24,
                        ),
                      ),
                      title: Text(job.serviceType),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (job.customerName.isNotEmpty && job.customerName != 'Customer')
                            Text('Customer: ${job.customerName}'),
                          if (job.vehiclePlate.isNotEmpty)
                            Text('Car: ${job.vehiclePlate}'),
                          if (job.addressText != null && job.addressText!.isNotEmpty)
                            Text('Location: ${job.addressText}'),
                          Text('Date: ${job.scheduledDate.day}/${job.scheduledDate.month}/${job.scheduledDate.year} ${job.scheduledTime}'),
                          if (job.paymentMethod.isNotEmpty)
                            Text('Payment: ${job.paymentMethod.toUpperCase()}'),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: getStatusColor(job.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getStatusText(job.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: getStatusColor(job.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'view') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailsScreen(job: job),
                              ),
                            ).then((_) {
                              setState(() {
                                jobsFuture = fetchJobs();
                              });
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Details'),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailsScreen(job: job),
                          ),
                        ).then((_) {
                          setState(() {
                            jobsFuture = fetchJobs();
                          });
                        });
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
