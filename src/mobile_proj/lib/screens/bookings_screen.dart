import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/wallet_service.dart';
import 'payment_screen.dart';
import 'rating_feedback_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with AutomaticKeepAliveClientMixin {
  int selectedTab = 0;
  final BookingService _bookingService = BookingService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
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
    List<Booking> bookings = [];
    if (selectedTab == 0) {
      bookings = _bookingService.getCurrentBookings();
    } else {
      bookings = _bookingService.getPastBookings();
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
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
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

  Widget _buildBookingCard(Booking booking) {
    Color statusColor = _getStatusColor(booking.status);
    String statusText = booking.getStatusText();

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
