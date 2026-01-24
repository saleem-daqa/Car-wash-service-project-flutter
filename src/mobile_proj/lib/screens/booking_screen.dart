import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_actions_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with WidgetsBindingObserver {
  List<Vehicle> vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVehicles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('DEBUG BOOKING: Screen resumed, reloading vehicles');
      _loadVehicles();
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id') ?? 0;
      
      print('DEBUG BOOKING: Loading vehicles for customerId = $customerId');
      
      if (customerId == 0) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost/carwash/get_all_vehicles.php'),
        body: {
          'customer_id': customerId.toString(),
        },
      );

      print('DEBUG BOOKING: Response status = ${response.statusCode}');
      print('DEBUG BOOKING: Response body = ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('DEBUG BOOKING: data = $data');
        
        if (data['status'] == 'success') {
          final vehiclesList = data['vehicles'] as List;
          print('DEBUG BOOKING: vehiclesList length = ${vehiclesList.length}');
          print('DEBUG BOOKING: vehiclesList = $vehiclesList');
          
          setState(() {
            vehicles = vehiclesList.map((v) {
              print('DEBUG BOOKING MAPPING: Full vehicle object: $v');
              
              final carId = v['car_id'];
              final brand = v['car_brand'] ?? v['brand'] ?? v['vehicle_brand'] ?? '';
              final model = v['car_model'] ?? v['model'] ?? '';
              final plate = v['plate_number'] ?? v['plate'] ?? '';
              
              print('DEBUG: Extracted - carId=$carId, brand="$brand", model="$model", plate="$plate"');
              
              if (brand.isEmpty) {
                print('WARNING: Brand is empty for vehicle: $v');
              }
              
              return Vehicle(
                type: 'Car/Sedan',
                brand: brand,
                model: model,
                plate: plate,
                carId: carId,
              );
            }).toList();
            _isLoading = false;
            print('DEBUG BOOKING: Loaded ${vehicles.length} vehicles');
            for (int i = 0; i < vehicles.length; i++) {
              print('DEBUG BOOKING: Vehicle $i: carId = ${vehicles[i].carId}');
            }
          });
        }
      }
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(
          onVehicleAdded: (vehicle) {
            // Reload vehicles from database after adding
            _loadVehicles();
          },
        ),
      ),
    );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
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
