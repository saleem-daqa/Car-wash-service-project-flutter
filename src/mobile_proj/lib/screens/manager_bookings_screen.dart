import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ManagerBookingsScreen extends StatefulWidget {
  const ManagerBookingsScreen({super.key});

  @override
  State<ManagerBookingsScreen> createState() => _ManagerBookingsScreenState();
}

class _ManagerBookingsScreenState extends State<ManagerBookingsScreen> {
  Future<List<dynamic>>? bookingsFuture;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  void loadBookings() {
    setState(() {
      bookingsFuture = fetchBookings();
    });
  }

  Future<List<dynamic>> fetchBookings() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.managerBookingsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['bookings'] != null) {
          return data['bookings'] as List;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return [];
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CONFIRMED':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          loadBookings();
          await bookingsFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return const Center(child: Text('No bookings found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final status = booking['status'] ?? 'UNKNOWN';
                final car = booking['car'] ?? {};
                final scheduledAt = booking['scheduled_at'] ?? '';
                DateTime? scheduledDate;
                try {
                  if (scheduledAt.isNotEmpty) {
                    scheduledDate = DateTime.parse(scheduledAt);
                  }
                } catch (e) {
                  scheduledDate = null;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking['service_name'] ?? 'Service',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Customer: ${booking['customer_name'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  if (booking['customer_phone'] != null)
                                    Text(
                                      'Phone: ${booking['customer_phone']}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.directions_car, size: 20, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              '${car['plate_number'] ?? 'N/A'} - ${car['brand'] ?? ''} ${car['model'] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (booking['address'] != null || booking['address_text'] != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking['address'] ?? booking['address_text'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        if (scheduledDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 20, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Payment: ${(booking['payment_method'] ?? 'cash').toString().toUpperCase()}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Spacer(),
                            if (booking['price_total'] != null)
                              Text(
                                '${(double.tryParse(booking['price_total'].toString()) ?? 0.0).toStringAsFixed(0)} ₪',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Employee: ${booking['employee_name'] ?? 'Not Assigned'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: booking['employee_name'] != null ? FontWeight.bold : FontWeight.normal,
                                color: booking['employee_name'] != null ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.groups, size: 20, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Team: ${booking['team_name'] ?? 'Not Assigned'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: booking['team_name'] != null ? FontWeight.bold : FontWeight.normal,
                                color: booking['team_name'] != null ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
