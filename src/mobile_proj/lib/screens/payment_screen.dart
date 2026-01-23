import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final double bookingAmount;
  final int bookingId;

  const PaymentScreen({
    Key? key,
    required this.bookingAmount,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double walletBalance = 0.00;
  bool isProcessing = false;

  bool canPay() {
    if (walletBalance >= widget.bookingAmount) {
      return true;
    }
    return false;
  }

  void processPayment() {
    if (!canPay()) {
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

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }

      setState(() {
        walletBalance = walletBalance - widget.bookingAmount;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of \$${widget.bookingAmount.toStringAsFixed(2)} successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canPayNow = canPay();
    Color balanceColor = const Color(0xff0095FF);
    if (!canPayNow) {
      balanceColor = Colors.red;
    }

    double balanceAfter = walletBalance - widget.bookingAmount;
    Color balanceAfterColor = Colors.green;
    if (!canPayNow) {
      balanceAfterColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
        title: const Text(
          'Payment',
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
            const SizedBox(height: 20),
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
                    'Booking Details',
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
                        'Booking ID:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '#${widget.bookingId}',
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
                        '\$${widget.bookingAmount.toStringAsFixed(2)}',
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
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${walletBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  if (!canPayNow) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Insufficient balance. Please recharge your wallet.',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    'Payment Summary',
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
                        'Amount to Pay:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '\$${widget.bookingAmount.toStringAsFixed(2)}',
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
                        'Balance After Payment:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '\$${balanceAfter.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: balanceAfterColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _buildPayButtonHandler(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0095FF),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _buildButtonChild(),
              ),
            ),
          ],
        ),
      ),
    );
  }

 VoidCallback? _buildPayButtonHandler() {
  if (canPay() && !isProcessing) {
    return processPayment;
  } else {
    return null;
  }
}


  Widget _buildButtonChild() {
    if (isProcessing) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      return const Text(
        'Pay Now',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }
  }
}
