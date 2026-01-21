import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job? job;

  const JobDetailsScreen({super.key, this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: job == null ? _emptyState() : _details(job!),
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                size: 52, color: AppTheme.primaryBlue.withOpacity(0.65)),
            const SizedBox(height: 12),
            const Text(
              'No job selected',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.darkBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Open job details from Employee jobs list after data is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(Job j) {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${j.id}\n${j.serviceType}\n${j.location}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
