import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'payment_screen.dart';
import 'rating_feedback_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with AutomaticKeepAliveClientMixin {
  int selectedTab = 0;
  bool isLoading = true;
  List<Booking> bookings = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = selectedTab == 0
        ? 'http://localhost/carwash/get_current_bookings.php'
        : 'http://localhost/carwash/get_past_bookings.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'user_id': userId.toString(),
        },
      );

     if (response.statusCode == 200) {
  final data = json.decode(response.body);

  if (data['status'] == 'success') {
    bookings = (data['bookings'] as List)
        .map((e) => Booking.fromJson(e))
        .toList();
  } else {
    bookings = [];
  }
} else {
        bookings = [];
      }
    } catch (e) {
      bookings = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                      fetchBookings();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: _buildCurrentTabDecoration(),
                      child: Center(
                        child: Text(
                          'Current',
                          style: _buildCurrentTabTextStyle(),
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
                      fetchBookings();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: _buildPastTabDecoration(),
                      child: Center(
                        child: Text(
                          'Past',
                          style: _buildPastTabTextStyle(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBookingsList()),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedTab == 0 ? 'No current bookings' : 'No past bookings',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    Color statusColor = _getStatusColor(booking.status);
    String statusText = booking.getStatusText();

    // Safe fallback for vehiclePlate (empty string if null)
    final vehiclePlate = booking.vehiclePlate ?? '';

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
        mainAxisSize: MainAxisSize.min, // Helps prevent overflow
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // prevent overflow
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking #${booking.id}',
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year} at ${booking.scheduledTime}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            vehiclePlate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              _buildActionButton(booking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Booking booking) {
    if (selectedTab == 0 && booking.status == BookingStatus.confirmed) {
      return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                bookingAmount: booking.price,
                bookingId: int.parse(booking.id.replaceAll('JOB-', '')),
              ),
            ),
          );
        },
        child: const Text(
          'Pay Now',
          style: TextStyle(
            color: Color(0xff0095FF),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (selectedTab == 1 && booking.status == BookingStatus.completed) {
      return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RatingFeedbackScreen(
                bookingId: int.parse(booking.id.replaceAll('JOB-', '')),
                serviceName: booking.serviceName,
              ),
            ),
          );
        },
        child: const Text(
          'Rate & Feedback',
          style: TextStyle(
            color: Color(0xff0095FF),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getStatusColor(BookingStatus status) {
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

  BoxDecoration _buildCurrentTabDecoration() {
    return BoxDecoration(
      color: selectedTab == 0 ? const Color(0xff0095FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
    );
  }

  TextStyle _buildCurrentTabTextStyle() {
    return TextStyle(
      fontWeight: FontWeight.w600,
      color: selectedTab == 0 ? Colors.white : Colors.grey[600],
    );
  }

  BoxDecoration _buildPastTabDecoration() {
    return BoxDecoration(
      color: selectedTab == 1 ? const Color(0xff0095FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
    );
  }

  TextStyle _buildPastTabTextStyle() {
    return TextStyle(
      fontWeight: FontWeight.w600,
      color: selectedTab == 1 ? Colors.white : Colors.grey[600],
    );
  }
}