import 'package:flutter/material.dart';

class RatingFeedbackScreen extends StatefulWidget {
  final int bookingId;
  final String serviceName;

  const RatingFeedbackScreen({
    Key? key,
    required this.bookingId,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<RatingFeedbackScreen> createState() => _RatingFeedbackScreenState();
}

class _RatingFeedbackScreenState extends State<RatingFeedbackScreen> {
  int rating = 0;
  final TextEditingController feedbackController = TextEditingController();
  bool isSubmitting = false;

  void submitFeedback() {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    });
  }

  void selectStar(int starNumber) {
    setState(() {
      rating = starNumber;
    });
  }

  String getRatingText() {
    if (rating == 1) {
      return 'Poor';
    }
    if (rating == 2) {
      return 'Fair';
    }
    if (rating == 3) {
      return 'Good';
    }
    if (rating == 4) {
      return 'Very Good';
    }
    if (rating == 5) {
      return 'Excellent';
    }
    return '';
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Rate & Feedback',
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
                    'Service Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.local_car_wash, color: Color(0xff0095FF), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.confirmation_number, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Booking #${widget.bookingId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Rate Your Experience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStarWidget(1),
                  _buildStarWidget(2),
                  _buildStarWidget(3),
                  _buildStarWidget(4),
                  _buildStarWidget(5),
                ],
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  getRatingText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            const Text(
              'Your Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                    'Tell us about your experience (Optional)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feedbackController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Write your feedback here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      contentPadding: const EdgeInsets.all(15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _buildSubmitButtonHandler(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0095FF),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _buildSubmitButtonChild(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarWidget(int starNumber) {
    IconData starIcon = Icons.star_border;
    Color starColor = Colors.grey[300]!;
    
    if (rating >= starNumber) {
      starIcon = Icons.star;
      starColor = Colors.amber;
    }

    return GestureDetector(
      onTap: () {
        selectStar(starNumber);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          starIcon,
          size: 48,
          color: starColor,
        ),
      ),
    );
  }

  VoidCallback? _buildSubmitButtonHandler() {
    if (isSubmitting) {
      return null;
    } else {
      return () {
        submitFeedback();
      };
    }
  }

  Widget _buildSubmitButtonChild() {
    if (isSubmitting) {
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
        'Submit Feedback',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }
  }
}
