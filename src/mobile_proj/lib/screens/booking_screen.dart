import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_actions_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Initialize with a dummy car for testing
  List<Vehicle> vehicles = [
    Vehicle(
      type: 'Car/Sedan',
      brand: 'Toyota',
      model: '2023',
      plate: 'ABC-1234',
    ),
  ];

  void _addVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(
          onVehicleAdded: (vehicle) {
            setState(() {
              vehicles.add(vehicle);
            });
          },
        ),
      ),
    );
    
    // Fallback: if callback didn't work, use result
    if (result != null && result is Vehicle) {
      // Check if vehicle with same plate already exists
      bool exists = vehicles.any((v) => v.plate == (result as Vehicle).plate);
      if (!exists) {
        setState(() {
          vehicles.add(result as Vehicle);
        });
      }
    }
  }

  void _onVehicleDeleted(int index) {
    setState(() {
      vehicles.removeAt(index);
    });
  }

  void _onVehicleEdited(Vehicle updatedVehicle, int index) {
    setState(() {
      vehicles[index] = updatedVehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: vehicles.isEmpty
          ? _buildEmptyState()
          : _buildVehiclesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash,
              size: 80,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Book a Car Wash',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your vehicle to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addVehicle,
              icon: const Icon(Icons.directions_car),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0095FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesList() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Vehicles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap on a vehicle to book a service',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                ...vehicles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final vehicle = entry.value;
                  return VehicleCard(
                    key: ValueKey('${vehicle.plate}-$index'),
                    vehicle: vehicle,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleActionsScreen(
                            vehicle: vehicle,
                            onVehicleDeleted: () => _onVehicleDeleted(index),
                            onVehicleEdited: (updatedVehicle) => _onVehicleEdited(updatedVehicle, index),
                          ),
                        ),
                      );
                      // Refresh if needed
                      if (result == true) {
                        setState(() {});
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ),
        // Add Vehicle Button at Bottom
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0095FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
