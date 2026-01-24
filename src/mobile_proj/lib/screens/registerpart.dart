import 'package:flutter/material.dart';
import 'customer_home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegistrationScreen extends StatefulWidget {
  final int userId; // Add this
  final String username;
  final String email;

  const RegistrationScreen({
    Key? key,
    required this.userId,
    required this.username,
    required this.email,
  }) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();

  void submit() async {
  if (_formKey.currentState!.validate()) {
    print('Validation passed, sending request...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost/carwash/complete_registration.php'),
        body: {
          'user_id': widget.userId.toString(),
          'phone': phoneController.text.trim(),
          'plate_number': plateNumberController.text.trim(),
          'car_model': carModelController.text.trim(),
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded response: $data');

        if (data['status'] == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to complete registration')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server')),
        );
      }
    } catch (e) {
      print('Exception in submit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } else {
    print('Validation failed');
  }
}


  Widget inputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Complete Registration for ${widget.username}'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                inputField(
                  label: 'Phone Number',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter phone number' : null,
                ),
                inputField(
                  label: 'Car Plate Number',
                  controller: plateNumberController,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter plate number' : null,
                ),
                inputField(
                  label: 'Car Model',
                  controller: carModelController,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter car model' : null,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: const Color(0xff0095FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Complete Registration',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
