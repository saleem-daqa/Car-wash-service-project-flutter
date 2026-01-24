import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup.dart';
import 'manager_home.dart';  
import 'customer_home_screen.dart';
import 'employee_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    final response = await http.post(
     Uri.parse('http://localhost/carwash/login.php'),
      body: {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      },
    );

   if (response.statusCode == 200) {
  final data = json.decode(response.body);
  print('DEBUG LOGIN: Response data = $data');

  if (data['status'] == 'success') {
    final role = data['role'];
    final userId = data['user_id'];
    print('DEBUG LOGIN: userId = $userId, role = $role');
    
     final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId ?? 0);
      await prefs.setString('user_role', role);
      
      final savedUserId = prefs.getInt('user_id');
      print('DEBUG LOGIN: Saved userId to SharedPreferences = $savedUserId');
      
    if (role == 'CUSTOMER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    } else if (role == 'EMPLOYEE') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeHome()),
      );
    } else if (role == 'MANAGER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerHome()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown user role')),
      );
    }
  } else {
    // Show the message from the server, if any
    final errorMessage = data['message'] ?? 'Login failed: Email or password is incorrect.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error connecting to server: ${response.statusCode}')),
  );
}

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Welcome back",
                          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: <Widget>[
                          inputFile(
                            label: "Email",
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(
                                r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          inputFile(
                            label: "Password",
                            obscureText: true,
                            controller: passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: login,
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
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text("Don't have an account?"),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupPage(),
                              ),
                            );
                          },
                          child: const Text(
                            " Sign up",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Color(0xff0095FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 100),
                      height: 200,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/welcome.png"),
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget inputFile({
  required String label,
  bool obscureText = false,
  TextEditingController? controller,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
