import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job? job;
  final String? bookingId;

  const JobDetailsScreen({super.key, this.job, this.bookingId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  Job? _job;
  Map<String, dynamic>? _jobDetails;
  bool _isLoading = false;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    if (widget.bookingId != null || widget.job != null) {
      _loadJobDetails();
    } else {
      _isLoadingDetails = false;
    }
  }

  Future<void> _loadJobDetails() async {
    final bookingId = widget.bookingId ?? widget.job?.id;
    if (bookingId == null) {
      setState(() => _isLoadingDetails = false);
      return;
    }

    setState(() => _isLoadingDetails = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.bookingGetDetailsUrl}?booking_id=$bookingId'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['job'] != null) {
          final jobData = data['job'];
          setState(() {
            _jobDetails = jobData;
            _job =
                _job ??
                Job(
                  id: jobData['booking_id'].toString(),
                  customerName: jobData['customer_name'] ?? 'Customer',
                  serviceType: jobData['service_name'] ?? 'Service',
                  vehiclePlate: jobData['car_plate'] ?? '',
                  latitude: jobData['latitude'] != null
                      ? (jobData['latitude'] is String
                            ? double.tryParse(jobData['latitude']) ?? 0.0
                            : (jobData['latitude'] as num).toDouble())
                      : 0.0,
                  longitude: jobData['longitude'] != null
                      ? (jobData['longitude'] is String
                            ? double.tryParse(jobData['longitude']) ?? 0.0
                            : (jobData['longitude'] as num).toDouble())
                      : 0.0,
                  addressText: jobData['address_text'] ?? '',
                  scheduledDate: jobData['scheduled_at'] != null
                      ? DateTime.parse(jobData['scheduled_at'])
                      : DateTime.now(),
                  scheduledTime: jobData['scheduled_at'] != null
                      ? '${DateTime.parse(jobData['scheduled_at']).hour}:${DateTime.parse(jobData['scheduled_at']).minute.toString().padLeft(2, '0')}'
                      : 'N/A',
                  paymentMethod: jobData['payment_method'] ?? 'cash',
                  status: _mapStatusFromApi(jobData['status'] ?? 'ASSIGNED'),
                );
            if (_job != null) {
              _job!.status = _mapStatusFromApi(jobData['status'] ?? 'ASSIGNED');
            }
            _isLoadingDetails = false;
          });
        } else {
          setState(() => _isLoadingDetails = false);
        }
      } else {
        setState(() => _isLoadingDetails = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  JobStatus _mapStatusFromApi(String apiStatus) {
    switch (apiStatus.toUpperCase()) {
      case 'ASSIGNED':
      case 'CONFIRMED':
        return JobStatus.assigned;
      case 'IN_PROGRESS':
        return JobStatus.inProgress;
      case 'COMPLETED':
        return JobStatus.completed;
      default:
        return JobStatus.assigned;
    }
  }

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
          content: Text(
            'Could not open maps app. Please install a maps application.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _startJob() async {
    final bookingId = widget.bookingId ?? widget.job?.id;
    if (bookingId == null) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getInt('user_id') ?? 0;

      if (employeeId == 0) {
        throw Exception('Employee ID not found');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.bookingUpdateStatusUrl),
        body: {
          'booking_id': bookingId,
          'action': 'start',
          'employee_id': employeeId.toString(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          await _loadJobDetails();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Could not start job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishJob() async {
    final bookingId = widget.bookingId ?? widget.job?.id;
    if (bookingId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish Job'),
        content: const Text(
          'Are you sure you want to mark this job as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);

              try {
                final response = await http.post(
                  Uri.parse(ApiConfig.bookingUpdateStatusUrl),
                  body: {'booking_id': bookingId, 'action': 'finish'},
                );

                if (!mounted) return;

                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['status'] == 'success') {
                    await _loadJobDetails();
                    if (!mounted) return;
                    final pointsAdded = data['points_added'] ?? 0;
                    final pointsExact =
                        data['points_exact'] ?? pointsAdded.toDouble();
                    final pricePaid = data['price_paid'] ?? 0.0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pointsAdded > 0
                              ? 'Job completed! ${pointsExact.toStringAsFixed(2)} points added (paid ${pricePaid.toStringAsFixed(0)} NIS, 15 NIS = 1 point).'
                              : 'Job completed successfully!',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          data['message'] ?? 'Could not finish job',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : (_job == null ? _emptyState() : _details(context, _job!)),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 52,
              color: AppTheme.primaryBlue.withValues(alpha: 0.65),
            ),
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
                  if (_jobDetails != null &&
                      _jobDetails!['customer_phone'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.phone,
                      'Phone',
                      _jobDetails!['customer_phone'] ?? 'N/A',
                    ),
                  ],
                  if (_jobDetails != null &&
                      _jobDetails!['customer_email'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.email,
                      'Email',
                      _jobDetails!['customer_email'] ?? 'N/A',
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.local_car_wash,
                    'Service',
                    j.serviceType,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.directions_car,
                    'Vehicle Plate',
                    j.vehiclePlate,
                  ),
                  if (_jobDetails != null &&
                      _jobDetails!['car_brand'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.directions_car,
                      'Brand',
                      '${_jobDetails!['car_brand']} ${_jobDetails!['car_model'] ?? ''}',
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    '${j.scheduledDate.day}/${j.scheduledDate.month}/${j.scheduledDate.year}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time, 'Time', j.scheduledTime),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.payment,
                    'Payment Method',
                    _getPaymentMethodText(j.paymentMethod),
                  ),
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
                          Icon(
                            Icons.location_city,
                            color: Colors.green[700],
                            size: 20,
                          ),
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
                        Icon(
                          Icons.my_location,
                          color: Colors.blue[700],
                          size: 20,
                        ),
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
          if (j.status == JobStatus.assigned ||
              j.status == JobStatus.inProgress) ...[
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
                          onPressed: _isLoading ? null : _startJob,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isLoading ? 'Starting...' : 'Start Job'),
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
                          onPressed: _isLoading ? null : _finishJob,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _isLoading ? 'Finishing...' : 'Finish Job',
                          ),
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
