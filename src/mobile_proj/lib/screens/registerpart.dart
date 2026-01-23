import 'package:flutter/material.dart';
import 'customer_home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String username;

  const RegistrationScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController carModelController = TextEditingController();

  void submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.username.toLowerCase() == 'shahd') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only username "shahd" can enter for now.')),
        );
      }
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
