import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'payment_screen.dart';
import 'rating_feedback_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../widgets/app_empty_state.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => BookingsScreenState();
}

class BookingsScreenState extends State<BookingsScreen> {
  int selectedTab = 0;
  Future<List<Booking>>? currentBookingsFuture;
  Future<List<Booking>>? pastBookingsFuture;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  void loadBookings() {
    setState(() {
      currentBookingsFuture = fetchCurrentBookings();
      pastBookingsFuture = fetchPastBookings();
    });
  }

  Future<List<Booking>> fetchCurrentBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      return [];
    }

    final response = await http.post(
      Uri.parse(ApiConfig.getCurrentBookingsUrl),
      body: {'user_id': customerId.toString()},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['bookings'] != null) {
        return (data['bookings'] as List).map((bookingData) {
          return Booking.fromJson(bookingData);
        }).toList();
      }
    }
    return [];
  }

  Future<List<Booking>> fetchPastBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      return [];
    }

    final response = await http.post(
      Uri.parse(ApiConfig.getPastBookingsUrl),
      body: {'user_id': customerId.toString()},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['bookings'] != null) {
        return (data['bookings'] as List).map((bookingData) {
          return Booking.fromJson(bookingData);
        }).toList();
      }
    }
    return [];
  }

  String getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.assigned:
        return 'Assigned';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.assigned:
        return Colors.purple;
      case BookingStatus.inProgress:
        return const Color(0xff0095FF);
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Current'),
                  icon: Icon(Icons.schedule_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Past'),
                  icon: Icon(Icons.history),
                ),
              ],
              selected: {selectedTab},
              onSelectionChanged: (selection) {
                setState(() => selectedTab = selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.standard,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primaryContainer;
                  }
                  return colorScheme.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary;
                  }
                  return colorScheme.onSurfaceVariant;
                }),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                loadBookings();
                return Future.value();
              },
              child: FutureBuilder<List<Booking>>(
                future: selectedTab == 0
                    ? currentBookingsFuture
                    : pastBookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        AppEmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load bookings',
                          message:
                              'Pull down to refresh, or try again in a moment.',
                        ),
                      ],
                    );
                  } else {
                    final bookings = snapshot.data ?? [];
                    if (bookings.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          AppEmptyState(
                            icon: selectedTab == 0
                                ? Icons.event_available_outlined
                                : Icons.history,
                            title: selectedTab == 0
                                ? 'No current bookings'
                                : 'No past bookings',
                            message: selectedTab == 0
                                ? 'Your active service bookings will appear here.'
                                : 'Completed and cancelled bookings will appear here.',
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        return buildBookingCard(bookings[index]);
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingCard(Booking booking) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = getStatusColor(booking.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                        Text(booking.serviceName, style: textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Booking #${booking.id}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getStatusText(booking.status),
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year} at ${booking.scheduledTime}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.vehiclePlate,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${booking.price.toStringAsFixed(2)} ₪',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  if (selectedTab == 0 &&
                      booking.status == BookingStatus.confirmed)
                    TextButton(
                      onPressed: () {
                        final bookingId =
                            int.tryParse(booking.id.replaceAll('JOB-', '')) ??
                            0;
                        if (bookingId > 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                bookingAmount: booking.price,
                                bookingId: bookingId,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Pay Now'),
                    ),
                  if (selectedTab == 1 &&
                      booking.status == BookingStatus.completed)
                    TextButton(
                      onPressed: () {
                        final bookingId =
                            int.tryParse(booking.id.replaceAll('JOB-', '')) ??
                            0;
                        if (bookingId > 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatingFeedbackScreen(
                                bookingId: bookingId,
                                serviceName: booking.serviceName,
                              ),
                            ),
                          ).then((_) {
                            loadBookings();
                          });
                        }
                      },
                      child: const Text('Rate & Feedback'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
