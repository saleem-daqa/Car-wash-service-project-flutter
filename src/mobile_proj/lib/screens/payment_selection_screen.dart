import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'customer_home_screen.dart';

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
    super.key,
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
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String? selectedPaymentMethod;
  Future<Map<String, dynamic>>? walletFuture;
  bool isProcessing = false;

  static const String cash = 'Cash';
  static const String visaCard = 'Visa Card';
  static const String wallet = 'Wallet';

  @override
  void initState() {
    super.initState();
    walletFuture = loadWallet();
  }

  Future<Map<String, dynamic>> loadWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      return {'balance': 0.0, 'points': 0};
    }

    final response = await http.post(
      Uri.parse(ApiConfig.getWalletUrl),
      body: {'customer_id': customerId.toString()},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return {
          'balance': (data['balance'] as num).toDouble(),
          'points': data['points'] as int,
        };
      }
    }
    return {'balance': 0.0, 'points': 0};
  }

  Future<int> createBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      throw Exception('User ID not found');
    }

    String paymentMethodApi = 'CASH';
    if (selectedPaymentMethod == visaCard) {
      paymentMethodApi = 'VISA';
    } else if (selectedPaymentMethod == wallet) {
      paymentMethodApi = 'WALLET';
    }

    final response = await http.post(
      Uri.parse(ApiConfig.createBookingUrl),
      body: {
        'customer_id': customerId.toString(),
        'car_id': widget.vehicle.carId.toString(),
        'service_name': widget.serviceName,
        'price': widget.bookingAmount.toString(),
        'booking_date': widget.scheduledDate.toString().split(' ')[0],
        'booking_time': widget.scheduledTime,
        'latitude': widget.latitude.toString(),
        'longitude': widget.longitude.toString(),
        'payment_method': paymentMethodApi,
        'address_text': widget.addressText.isEmpty ? '' : widget.addressText,
        'notes': widget.notes.isEmpty ? '' : widget.notes,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['booking_id'] != null) {
        return data['booking_id'] as int;
      }
      throw Exception(data['message'] ?? 'Failed to create booking');
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<void> processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final walletData = await walletFuture;
      final walletBalance = walletData?['balance'] ?? 0.0;

      if (selectedPaymentMethod == wallet && walletBalance < widget.bookingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient wallet balance'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final bookingId = await createBooking();

      if (!mounted) return;

      String paymentMethodText;
      if (selectedPaymentMethod == cash) {
        paymentMethodText = 'Cash payment';
      } else if (selectedPaymentMethod == visaCard) {
        paymentMethodText = 'Visa Card payment';
      } else {
        paymentMethodText = 'Wallet payment';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! Booking #$bookingId created'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen(initialTab: 2)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget buildPaymentOption(String method, IconData icon, Color color) {
    return FutureBuilder<Map<String, dynamic>>(
      future: walletFuture,
      builder: (context, snapshot) {
        final walletBalance = snapshot.data?['balance'] ?? 0.0;
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
                        snapshot.connectionState == ConnectionState.waiting
                            ? const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              )
                            : Text(
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
      },
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
            buildPaymentOption(cash, Icons.money, Colors.green),
            buildPaymentOption(visaCard, Icons.credit_card, Colors.blue),
            buildPaymentOption(wallet, Icons.account_balance_wallet, Colors.purple),
            const SizedBox(height: 30),
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
