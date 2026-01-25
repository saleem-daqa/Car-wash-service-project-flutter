import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'payment_screen.dart';
import 'rating_feedback_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedTab == 0 ? const Color(0xff0095FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedTab == 0 ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedTab == 1 ? const Color(0xff0095FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          'Past',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedTab == 1 ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                loadBookings();
                return Future.value();
              },
              child: FutureBuilder<List<Booking>>(
                future: selectedTab == 0 ? currentBookingsFuture : pastBookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Oops: ${snapshot.error}'));
                  } else {
                    final bookings = snapshot.data ?? [];
                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          selectedTab == 0 ? 'No current bookings' : 'No past bookings',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking #${booking.id}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getStatusText(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: getStatusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year} at ${booking.scheduledTime}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                booking.vehiclePlate,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking.price.toStringAsFixed(2)} ₪',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0095FF),
                ),
              ),
              if (selectedTab == 0 && booking.status == BookingStatus.confirmed)
                TextButton(
                  onPressed: () {
                    final bookingId = int.tryParse(booking.id.replaceAll('JOB-', '')) ?? 0;
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
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(
                      color: Color(0xff0095FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (selectedTab == 1 && booking.status == BookingStatus.completed)
                TextButton(
                  onPressed: () {
                    final bookingId = int.tryParse(booking.id.replaceAll('JOB-', '')) ?? 0;
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
                  child: const Text(
                    'Rate & Feedback',
                    style: TextStyle(
                      color: Color(0xff0095FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
