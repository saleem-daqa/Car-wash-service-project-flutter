import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/booking.dart';
import '../services/job_service.dart';
import '../services/booking_service.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final double bookingAmount;
  final int bookingId;
  final String serviceName;
  final dynamic vehicle;
  final double latitude;
  final double longitude;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String notes;
  final String addressText;

  const PaymentSelectionScreen({
    Key? key,
    required this.bookingAmount,
    required this.bookingId,
    required this.serviceName,
    required this.vehicle,
    required this.latitude,
    required this.longitude,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.notes,
    required this.addressText,
  }) : super(key: key);

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String? selectedPaymentMethod;
  double walletBalance = 0.00; // This should come from shared state or provider
  bool isProcessing = false;

  // Payment methods
  static const String cash = 'Cash';
  static const String visaCard = 'Visa Card';
  static const String wallet = 'Wallet';

  void processPayment() {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == wallet && walletBalance < widget.bookingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      String paymentMethodText = '';
      switch (selectedPaymentMethod) {
        case cash:
          paymentMethodText = 'Cash payment';
          break;
        case visaCard:
          paymentMethodText = 'Visa Card payment';
          break;
        case wallet:
          paymentMethodText = 'Wallet payment';
          walletBalance = walletBalance - widget.bookingAmount;
          break;
      }

      final jobId = 'JOB-${DateTime.now().millisecondsSinceEpoch}';
      final job = Job(
        id: jobId,
        customerName: 'Customer',
        serviceType: widget.serviceName,
        vehiclePlate: widget.vehicle.plate,
        latitude: widget.latitude,
        longitude: widget.longitude,
        addressText: widget.addressText.isEmpty ? null : widget.addressText,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
        notes: widget.notes.isEmpty ? null : widget.notes,
        paymentMethod: selectedPaymentMethod!,
        status: JobStatus.assigned,
      );

      JobService().addJob(job);

      final booking = Booking(
        id: jobId,
        vehiclePlate: widget.vehicle.plate,
        serviceName: widget.serviceName,
        price: widget.bookingAmount,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
        latitude: widget.latitude,
        longitude: widget.longitude,
        notes: widget.notes.isEmpty ? null : widget.notes,
        paymentMethod: selectedPaymentMethod!,
        status: BookingStatus.confirmed,
      );

      BookingService().addBooking(booking);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$paymentMethodText of ${widget.bookingAmount.toStringAsFixed(2)} ₪ successful!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  Widget _buildPaymentOption(String method, IconData icon, Color color) {
    bool isSelected = selectedPaymentMethod == method;
    bool isWallet = method == wallet;
    bool canUseWallet = isWallet && walletBalance >= widget.bookingAmount;

    return InkWell(
      onTap: () {
        if (isWallet && !canUseWallet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient wallet balance'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  if (isWallet) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Balance: ${walletBalance.toStringAsFixed(2)} ₪',
                      style: TextStyle(
                        fontSize: 12,
                        color: canUseWallet ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
        title: const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            Container(
              width: double.infinity,
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
                  const Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        widget.serviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        '${widget.bookingAmount.toStringAsFixed(2)} ₪',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0095FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Payment Options
            _buildPaymentOption(cash, Icons.money, Colors.green),
            _buildPaymentOption(visaCard, Icons.credit_card, Colors.blue),
            _buildPaymentOption(wallet, Icons.account_balance_wallet, Colors.purple),

            const SizedBox(height: 30),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0095FF),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
