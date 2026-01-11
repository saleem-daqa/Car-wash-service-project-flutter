import 'package:flutter/material.dart';

class ManagerHome extends StatelessWidget {
  const ManagerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Home"),
      ),
      body: const Center(
        child: Text(
          "Welcome Manager",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
