import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/wash_service.dart';
import 'location_time_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WashServiceScreen extends StatefulWidget {
  final Vehicle vehicle;

  const WashServiceScreen({super.key, required this.vehicle});

  @override
  State<WashServiceScreen> createState() => _WashServiceScreenState();
}

class _WashServiceScreenState extends State<WashServiceScreen> {
  Future<List<WashService>>? servicesFuture;

  @override
  void initState() {
    super.initState();
    servicesFuture = loadServices();
  }

  Future<List<WashService>> loadServices() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.servicesListUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> servicesList = [];

        if (data['status'] == 'success' && data['services'] != null) {
          servicesList = data['services'] as List;
        } else if (data['ok'] == true &&
            data['data'] != null &&
            data['data']['services'] != null) {
          servicesList = data['data']['services'] as List;
        }

        if (servicesList.isNotEmpty) {
          return servicesList.map((s) {
            final price = double.tryParse((s['price'] ?? 0).toString()) ?? 0.0;
            return WashService(
              name: s['name'] ?? '',
              description: s['description'] ?? '',
              priceCar: price,
              priceBus: price * 1.5,
              priceMotorcycle: price * 0.7,
            );
          }).toList();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return [];
  }

  IconData getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('basic')) return Icons.local_car_wash;
    if (name.contains('deluxe')) return Icons.cleaning_services;
    if (name.contains('premium')) return Icons.star;
    return Icons.local_car_wash;
  }

  Color getServiceColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('basic')) return Colors.blue;
    if (name.contains('deluxe')) return Colors.orange;
    if (name.contains('premium')) return Colors.purple;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Select Wash Service',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 40,
                      color: Color(0xff0095FF),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.vehicle.brand} ${widget.vehicle.model}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Plate: ${widget.vehicle.plate}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Type: ${widget.vehicle.type}',
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
              'Select Your Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B3BAA),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<WashService>>(
                future: servicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    return Center(child: Text('No services available'));
                  }
                  final services = snapshot.data!;
                  return ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      final price = service.getPrice(widget.vehicle.type);
                      final icon = getServiceIcon(service.name);
                      final color = getServiceColor(service.name);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 32),
                          ),
                          title: Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              service.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          trailing: Text(
                            '${price.toStringAsFixed(0)} ₪',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationTimeScreen(
                                  vehicle: widget.vehicle,
                                  service: service,
                                  price: price,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
