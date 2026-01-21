import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import 'job_details_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final List<Job> jobs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 12),

          if (jobs.isEmpty) _emptyState(context),

          ...jobs.map((job) => Card(
            child: ListTile(
              title: Text(
                job.serviceType,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkBlue,
                ),
              ),
              subtitle: Text(job.location),
              trailing: const Icon(Icons.open_in_new,
                  color: AppTheme.primaryBlue),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailsScreen(job: job),
                  ),
                );
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
              child:
              const Icon(Icons.work_outline, color: AppTheme.primaryBlue),
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

  Widget _emptyState(BuildContext context) {
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
}
