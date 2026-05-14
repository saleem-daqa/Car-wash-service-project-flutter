import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/vehicle.dart';
import '../widgets/app_button.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_text_field.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_actions_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<Vehicle>>? vehiclesFuture;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    vehiclesFuture = loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _refreshVehicles() {
    setState(() {
      vehiclesFuture = loadVehicles();
    });
    return vehiclesFuture!;
  }

  void addVehicle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(
          onVehicleAdded: (_) {
            setState(() {
              vehiclesFuture = loadVehicles();
            });
          },
        ),
      ),
    );
  }

  List<Vehicle> _filterVehicles(List<Vehicle> vehicles) {
    final query = _searchTerm.trim().toLowerCase();
    if (query.isEmpty) return vehicles;

    return vehicles.where((vehicle) {
      final searchable =
          '${vehicle.brand} ${vehicle.model} ${vehicle.plate} ${vehicle.type}'
              .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _refreshVehicles,
        child: FutureBuilder<List<Vehicle>>(
          future: vehiclesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  AppEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load vehicles',
                    message: 'Pull down to refresh, or try again in a moment.',
                    actionLabel: 'Try again',
                    onAction: _refreshVehicles,
                  ),
                ],
              );
            }

            final vehicles = snapshot.data ?? [];
            if (vehicles.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  AppEmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No vehicles yet',
                    message:
                        'Add your first vehicle to start booking car wash services.',
                    actionLabel: 'Add vehicle',
                    onAction: addVehicle,
                  ),
                ],
              );
            }

            final filteredVehicles = _filterVehicles(vehicles);

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppButton(
                  label: 'Add new vehicle',
                  icon: Icons.add,
                  onPressed: addVehicle,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Search vehicles',
                  hintText: 'Brand, model, plate, or type',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  suffixIcon: _searchTerm.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchTerm = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  onChanged: (value) => setState(() => _searchTerm = value),
                ),
                if (filteredVehicles.isEmpty)
                  AppEmptyState(
                    icon: Icons.search_off,
                    title: 'No matching vehicles',
                    message:
                        'Try another brand, model, plate number, or vehicle type.',
                    actionLabel: 'Clear search',
                    onAction: () {
                      _searchController.clear();
                      setState(() => _searchTerm = '');
                    },
                  )
                else
                  ...filteredVehicles.map((vehicle) {
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
                              onVehicleEdited: (_) {
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
            );
          },
        ),
      ),
    );
  }
}
