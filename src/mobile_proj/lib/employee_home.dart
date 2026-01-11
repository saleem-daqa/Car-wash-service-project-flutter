import 'package:flutter/material.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Home"),
      ),
      body: const Center(
        child: Text(
          "Welcome Employee Team",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
