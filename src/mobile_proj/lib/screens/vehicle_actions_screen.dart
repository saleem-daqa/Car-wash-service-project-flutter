import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/wash_service.dart';
import 'wash_service_screen.dart';
import 'add_edit_vehicle_screen.dart';

class VehicleActionsScreen extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onVehicleDeleted;
  final Function(Vehicle) onVehicleEdited;

  const VehicleActionsScreen({
    super.key,
    required this.vehicle,
    required this.onVehicleDeleted,
    required this.onVehicleEdited,
  });

  void _deleteVehicle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.brand} ${vehicle.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onVehicleDeleted();
              Navigator.pop(context); // Go back to booking screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${vehicle.brand} ${vehicle.model} deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _editVehicle(BuildContext context) async {
    final updatedVehicle = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(
          vehicleToEdit: vehicle,
          onVehicleUpdated: (v) {
            onVehicleEdited(v);
          },
        ),
      ),
    );
    
    if (updatedVehicle != null && updatedVehicle is Vehicle) {
      onVehicleEdited(updatedVehicle);
      Navigator.pop(context); // Go back to booking screen
    }
  }

  void _getService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WashServiceScreen(
          vehicle: vehicle,
          services: [
            WashService(
              name: 'Basic Wash',
              description: 'Complete exterior hand wash with premium soap, thorough tire cleaning and shining, wheel wells cleaned, windows wiped, and quick interior wipe-down',
              priceCar: 15,
              priceBus: 25,
              priceMotorcycle: 10,
            ),
            WashService(
              name: 'Deluxe Wash',
              description: 'Everything in Basic plus full interior vacuuming, dashboard and console cleaning, leather conditioning, tire dressing, and wax protection for lasting shine',
              priceCar: 25,
              priceBus: 40,
              priceMotorcycle: 15,
            ),
            WashService(
              name: 'Premium Wash',
              description: 'Complete Deluxe service plus engine bay cleaning, undercarriage wash, clay bar treatment, premium wax application, and interior detailing with odor elimination',
              priceCar: 40,
              priceBus: 60,
              priceMotorcycle: 25,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'Car/Sedan':
        return Icons.directions_car;
      case 'Bus/Truck':
        return Icons.directions_bus;
      case 'Motorcycle/Scooter':
        return Icons.motorcycle;
      default:
        return Icons.directions_car;
    }
  }

  Color _getVehicleColor(String type) {
    switch (type) {
      case 'Car/Sedan':
        return Colors.blue;
      case 'Bus/Truck':
        return Colors.orange;
      case 'Motorcycle/Scooter':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getVehicleColor(vehicle.type);
    final icon = _getVehicleIcon(vehicle.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Vehicle Options'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Vehicle Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.plate,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicle.type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButton(
              context,
              icon: Icons.local_car_wash,
              title: 'Get Service',
              subtitle: 'Book a car wash for this vehicle',
              color: const Color(0xff0095FF),
              onTap: () => _getService(context),
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              context,
              icon: Icons.edit,
              title: 'Edit Vehicle',
              subtitle: 'Update vehicle information',
              color: Colors.orange,
              onTap: () => _editVehicle(context),
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              context,
              icon: Icons.delete,
              title: 'Delete Vehicle',
              subtitle: 'Remove this vehicle from your account',
              color: Colors.red,
              onTap: () => _deleteVehicle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
