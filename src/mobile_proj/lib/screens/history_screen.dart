import 'package:flutter/material.dart';
import 'payment_screen.dart';
import 'rating_feedback_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int selectedTab = 0;
  List<Map<String, dynamic>> currentBookings = [];
  List<Map<String, dynamic>> pastBookings = [];

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
          Expanded(
            child: _buildBookingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    List<Map<String, dynamic>> bookings = [];
    if (selectedTab == 0) {
      bookings = currentBookings;
    } else {
      bookings = pastBookings;
    }

    if (bookings.isEmpty) {
      String message = 'No current bookings';
      if (selectedTab == 1) {
        message = 'No past bookings';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    String status = booking['status'] as String;
    Color statusColor = Colors.grey;
    if (status == 'PENDING') {
      statusColor = Colors.orange;
    } else if (status == 'CONFIRMED') {
      statusColor = Colors.blue;
    } else if (status == 'ASSIGNED') {
      statusColor = Colors.purple;
    } else if (status == 'IN_PROGRESS') {
      statusColor = const Color(0xff0095FF);
    } else if (status == 'COMPLETED') {
      statusColor = Colors.green;
    } else if (status == 'CANCELLED') {
      statusColor = Colors.red;
    }

    String statusText = status;
    if (status == 'PENDING') {
      statusText = 'Pending';
    } else if (status == 'CONFIRMED') {
      statusText = 'Confirmed';
    } else if (status == 'ASSIGNED') {
      statusText = 'Assigned';
    } else if (status == 'IN_PROGRESS') {
      statusText = 'In Progress';
    } else if (status == 'COMPLETED') {
      statusText = 'Completed';
    } else if (status == 'CANCELLED') {
      statusText = 'Cancelled';
    }

    bool canRate = false;
    if (booking.containsKey('canRate')) {
      canRate = booking['canRate'] == true;
    }

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
                      booking['service'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking #${booking['id']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${booking['date']} at ${booking['time']}',
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
                booking['car'],
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${booking['amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0095FF),
                ),
              ),
              _buildActionButton(status, canRate, booking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String status, bool canRate, Map<String, dynamic> booking) {
    if (selectedTab == 0 && status == 'CONFIRMED') {
      return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                bookingAmount: booking['amount'] as double,
                bookingId: booking['id'] as int,
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

    if (selectedTab == 1 && canRate) {
      return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RatingFeedbackScreen(
                bookingId: booking['id'] as int,
                serviceName: booking['service'] as String,
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

  BoxDecoration _buildCurrentTabDecoration() {
    Color tabColor = Colors.transparent;
    if (selectedTab == 0) {
      tabColor = const Color(0xff0095FF);
    }
    return BoxDecoration(
      color: tabColor,
      borderRadius: BorderRadius.circular(15),
    );
  }

  TextStyle _buildCurrentTabTextStyle() {
    Color textColor = Colors.grey[600]!;
    if (selectedTab == 0) {
      textColor = Colors.white;
    }
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
  }

  BoxDecoration _buildPastTabDecoration() {
    Color tabColor = Colors.transparent;
    if (selectedTab == 1) {
      tabColor = const Color(0xff0095FF);
    }
    return BoxDecoration(
      color: tabColor,
      borderRadius: BorderRadius.circular(15),
    );
  }

  TextStyle _buildPastTabTextStyle() {
    Color textColor = Colors.grey[600]!;
    if (selectedTab == 1) {
      textColor = Colors.white;
    }
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
  }
}
