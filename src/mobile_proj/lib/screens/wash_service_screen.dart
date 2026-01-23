import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/wash_service.dart';
import 'location_time_screen.dart';

class WashServiceScreen extends StatefulWidget {
  final Vehicle vehicle;
  final List<WashService> services;

  const WashServiceScreen({
    super.key,
    required this.vehicle,
    required this.services,
  });

  @override
  State<WashServiceScreen> createState() => _WashServiceScreenState();
}

class _WashServiceScreenState extends State<WashServiceScreen> {
  // Helper method to get service icon
  IconData getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'Basic Wash':
        return Icons.local_car_wash;
      case 'Deluxe Wash':
        return Icons.cleaning_services;
      case 'Premium Wash':
        return Icons.star;
      default:
        return Icons.local_car_wash;
    }
  }

  // Helper method to get service color
  Color getServiceColor(String serviceName) {
    switch (serviceName) {
      case 'Basic Wash':
        return Colors.blue;
      case 'Deluxe Wash':
        return Colors.orange;
      case 'Premium Wash':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Select Wash Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 3, color: Colors.black45, offset: Offset(1, 1))],
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 6,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/car_wash_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Simple vehicle info
                Card(
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car, size: 40, color: Colors.blue),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.vehicle.brand} ${widget.vehicle.model}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('Plate: ${widget.vehicle.plate}'),
                              Text('Type: ${widget.vehicle.type}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Simple title
                Text(
                  'Select Your Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Simple services list
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.services.length,
                    itemBuilder: (context, index) {
                      final service = widget.services[index];
                      final price = service.getPrice(widget.vehicle.type);
                      final icon = getServiceIcon(service.name);
                      final color = getServiceColor(service.name);

                      return Card(
                        color: Colors.white.withOpacity(0.95),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(icon, color: color, size: 40),
                          title: Text(service.name, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(service.description),
                          trailing: Text(
                            '\$${price.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
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
