import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import '../services/job_service.dart';
import 'job_details_screen.dart';
import 'loginscreen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  List<Job> jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      jobs = JobService().jobs;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadJobs();
  }

  void _updateJobStatus(Job job, JobStatus newStatus) {
    JobService().updateJobStatus(job.id, newStatus);
    _loadJobs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job ${job.id} status updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _logout() {
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
        title: const Text('Employee Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 12),
          if (jobs.isEmpty) _emptyState(),
          ...jobs.map((job) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(job.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(job.status),
                  color: _getStatusColor(job.status),
                  size: 24,
                ),
              ),
              title: Text(
                job.serviceType,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkBlue,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.customerName),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.red[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.addressText != null && job.addressText!.isNotEmpty
                              ? job.addressText!
                              : job.getLocationString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.payment, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getPaymentMethodText(job.paymentMethod),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(job.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(job.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(job.status),
                      ),
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.primaryBlue),
                onSelected: (value) {
                  if (value == 'view_details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(job: job),
                      ),
                    ).then((_) {
                      _loadJobs();
                    });
                  } else if (value == 'start' && job.status == JobStatus.assigned) {
                    _updateJobStatus(job, JobStatus.inProgress);
                  } else if (value == 'complete' && job.status == JobStatus.inProgress) {
                    _updateJobStatus(job, JobStatus.completed);
                  }
                },
                itemBuilder: (context) {
                  List<PopupMenuEntry<String>> items = [
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                  ];
                  
                  if (job.status == JobStatus.assigned) {
                    items.add(
                      const PopupMenuItem(
                        value: 'start',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Start Job', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (job.status == JobStatus.inProgress) {
                    items.add(
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Mark Complete', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return items;
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailsScreen(job: job),
                  ),
                ).then((_) {
                  _loadJobs();
                });
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.work_outline, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Assigned Jobs',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkBlue,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: AppTheme.primaryBlue.withOpacity(0.65),
            ),
            const SizedBox(height: 12),
            const Text(
              'No jobs assigned yet',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.darkBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jobs will appear here once assignments are created.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Icons.assignment;
      case JobStatus.inProgress:
        return Icons.local_car_wash;
      case JobStatus.completed:
        return Icons.check_circle;
    }
  }

  String _getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'visa':
        return 'Visa Card';
      case 'wallet':
        return 'Wallet';
      default:
        return method;
    }
  }
}
