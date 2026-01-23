import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import '../services/job_service.dart';
import '../services/wallet_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job? job;

  const JobDetailsScreen({super.key, this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final WalletService _walletService = WalletService();

  void _openMap(Job job) async {
    if (!mounted) return;

    final lat = job.latitude;
    final lng = job.longitude;

    final uris = [
      Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      Uri.parse('https://maps.google.com/?q=$lat,$lng'),
    ];

    bool opened = false;
    for (final uri in uris) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          opened = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps app. Please install a maps application.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _startJob() {
    if (widget.job == null) return;
    
    JobService().updateJobStatus(widget.job!.id, JobStatus.inProgress);
    
    try {
      BookingService().updateBookingStatus(widget.job!.id, BookingStatus.inProgress);
    } catch (e) {
    }
    
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job started'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _finishJob() {
    if (widget.job == null) return;

    final bookingService = BookingService();
    Booking? booking;
    try {
      booking = bookingService.bookings.firstWhere((b) => b.id == widget.job!.id);
    } catch (e) {
      booking = null;
    }

    final servicePrice = booking?.price ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Job'),
        content: const Text('Are you sure you want to mark this job as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              JobService().updateJobStatus(widget.job!.id, JobStatus.completed);
              
              if (booking != null) {
                BookingService().updateBookingStatus(widget.job!.id, BookingStatus.completed);
              }
              
              _walletService.addPointsFromCompletedService(widget.job!.serviceType);
              
              setState(() {});
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job completed! Points added to wallet.'),
                  backgroundColor: Colors.green,
                ),
              );
              
              Navigator.pop(context);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: widget.job == null ? _emptyState() : _details(context, widget.job!),
    );
  }

  Widget _emptyState() {
    return Center(
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
              'Open job details from Employee jobs list.',
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

  Widget _details(BuildContext context, Job j) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        j.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkBlue,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildDetailRow(Icons.person, 'Customer', j.customerName),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.local_car_wash, 'Service', j.serviceType),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.directions_car, 'Vehicle Plate', j.vehiclePlate),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_today, 'Date', 
                    '${j.scheduledDate.day}/${j.scheduledDate.month}/${j.scheduledDate.year}'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time, 'Time', j.scheduledTime),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.payment, 'Payment Method', _getPaymentMethodText(j.paymentMethod)),
                  if (j.notes != null && j.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.note, 'Notes', j.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  if (j.addressText != null && j.addressText!.isNotEmpty) ...[
                    Text(
                      'Address:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_city, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              j.addressText!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Coordinates:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat: ${j.latitude.toStringAsFixed(5)}, Lng: ${j.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(j),
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (j.status == JobStatus.assigned || j.status == JobStatus.inProgress) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (j.status == JobStatus.assigned)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startJob,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Job'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (j.status == JobStatus.inProgress) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _finishJob,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Finish Job'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
