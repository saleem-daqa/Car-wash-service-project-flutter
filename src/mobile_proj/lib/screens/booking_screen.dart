import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_actions_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Future<List<Vehicle>>? vehiclesFuture;

  @override
  void initState() {
    super.initState();
    vehiclesFuture = loadVehicles();
  }

  Future<List<Vehicle>> loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      return [];
    }

    final response = await http.post(
      Uri.parse(ApiConfig.getAllVehiclesUrl),
      body: {'customer_id': customerId.toString()},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final vehiclesList = data['vehicles'] as List;
        return vehiclesList.map((v) => Vehicle.fromJson(v)).toList();
      }
    }
    return [];
  }

  void addVehicle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(
          onVehicleAdded: (vehicle) {
            setState(() {
              vehiclesFuture = loadVehicles();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<List<Vehicle>>(
        future: vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          } else {
            final vehicles = snapshot.data ?? [];
            if (vehicles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No vehicles yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: addVehicle,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () {
                setState(() {
                  vehiclesFuture = loadVehicles();
                });
                return vehiclesFuture!;
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ElevatedButton.icon(
                    onPressed: addVehicle,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Vehicle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0095FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...vehicles.map((vehicle) {
                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleActionsScreen(
                              vehicle: vehicle,
                              onVehicleDeleted: () {
                                setState(() {
                                  vehiclesFuture = loadVehicles();
                                });
                              },
                              onVehicleEdited: (updatedVehicle) {
                                setState(() {
                                  vehiclesFuture = loadVehicles();
                                });
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
