import 'package:flutter/material.dart';
import 'customer_home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class RegistrationScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String email;

  const RegistrationScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.email,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController carBrandController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();

  void submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse(ApiConfig.completeRegistrationUrl),
          body: {
            'user_id': widget.userId.toString(),
            'plate_number': plateNumberController.text.trim(),
            'car_brand': carBrandController.text.trim(),
            'car_model': carModelController.text.trim(),
          },
        );

        if (!mounted) return;
        if (response.statusCode == 200) {
          final responseBody = response.body.trim();

          if (responseBody.isEmpty || !responseBody.startsWith('{')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server error, please try again'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          try {
            final data = json.decode(responseBody);

            if (data['status'] == 'success') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('user_id', widget.userId);

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data['message'] ?? 'Registration failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (jsonError) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Server response error: $jsonError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not connect to server'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Complete Registration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xff0095FF),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add Your Vehicle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B3BAA),
                  ),
                ),
                const SizedBox(height: 20),
                inputField(
                  label: 'Car Plate Number',
                  controller: plateNumberController,
                  icon: Icons.confirmation_number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter plate number'
                      : null,
                ),
                inputField(
                  label: 'Car Brand',
                  controller: carBrandController,
                  icon: Icons.directions_car,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter car brand';
                    }
                    if (value.trim().length < 2) {
                      return 'Brand must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                inputField(
                  label: 'Car Model (Year - Numbers Only)',
                  controller: carModelController,
                  keyboardType: TextInputType.number,
                  icon: Icons.calendar_today,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter car model year';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                      return 'Model must be numbers only (e.g., 2023)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: const Color(0xff0095FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Complete Registration',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
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

  Widget inputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xff0095FF))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff0095FF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
