import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vehicle.dart';
import '../models/wash_service.dart';
import 'wash_service_screen.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit;
  final Function(Vehicle)? onVehicleAdded;
  final Function(Vehicle)? onVehicleUpdated;

  const AddEditVehicleScreen({
    super.key,
    this.vehicleToEdit,
    this.onVehicleAdded,
    this.onVehicleUpdated,
  });

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  final List<String> vehicleTypes = ['Car/Sedan', 'Bus/Truck', 'Motorcycle/Scooter'];
  String? selectedType;
  List<Vehicle> vehicles = [];
  int? editingIndex;
  bool isEditingMode = false;

  bool typeTouched = false;
  bool brandTouched = false;
  bool modelTouched = false;
  bool plateTouched = false;

  String? typeError;
  String? brandError;
  String? modelError;
  String? plateError;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleToEdit != null) {
      isEditingMode = true;
      selectedType = widget.vehicleToEdit!.type;
      brandController.text = widget.vehicleToEdit!.brand;
      modelController.text = widget.vehicleToEdit!.model;
      plateController.text = widget.vehicleToEdit!.plate;
    } else {
      vehicles = [
        Vehicle(
          type: 'Car/Sedan',
          brand: 'Toyota',
          model: '2023',
          plate: 'ABC-1234',
        ),
      ];
    }
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    plateController.dispose();
    super.dispose();
  }

  IconData getVehicleIcon(String type) {
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

  void validateField(String field) {
    setState(() {
      switch (field) {
        case 'type':
          typeTouched = true;
          typeError = selectedType == null ? 'Please select a vehicle type' : null;
          break;
        case 'brand':
          brandTouched = true;
          final brand = brandController.text.trim();
          if (brand.isEmpty) {
            brandError = 'Please enter the vehicle brand';
          } else if (!Vehicle.isValidBrand(brand)) {
            brandError = 'Brand must be between 2 and 50 characters';
          } else {
            brandError = null;
          }
          break;
        case 'model':
          modelTouched = true;
          final model = modelController.text.trim();
          if (model.isEmpty) {
            modelError = 'Please enter the vehicle model';
          } else if (!Vehicle.isValidModel(model)) {
            modelError = 'Model must contain only numbers';
          } else {
            modelError = null;
          }
          break;
        case 'plate':
          plateTouched = true;
          final plate = plateController.text.trim();
          if (plate.isEmpty) {
            plateError = 'Please enter the plate number';
          } else if (!Vehicle.isValidPlate(plate)) {
            plateError = 'Plate number must be between 3 and 15 characters';
          } else {
            plateError = null;
          }
          break;
      }
    });
  }

  bool validateAllFields() {
    setState(() {
      typeTouched = true;
      brandTouched = true;
      modelTouched = true;
      plateTouched = true;
    });

    validateField('type');
    validateField('brand');
    validateField('model');
    validateField('plate');

    return typeError == null &&
        brandError == null &&
        modelError == null &&
        plateError == null;
  }

  void clearValidation() {
    setState(() {
      typeTouched = false;
      brandTouched = false;
      modelTouched = false;
      plateTouched = false;
      typeError = null;
      brandError = null;
      modelError = null;
      plateError = null;
    });
  }

  void addVehicle() {
    if (!validateAllFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vehicle = Vehicle(
      type: selectedType!,
      brand: brandController.text.trim(),
      model: modelController.text.trim(),
      plate: plateController.text.trim().toUpperCase(),
    );

    if (isEditingMode || editingIndex != null) {
      if (widget.onVehicleUpdated != null) {
        widget.onVehicleUpdated!(vehicle);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, vehicle);
    } else {
      if (widget.onVehicleAdded != null) {
        widget.onVehicleAdded!(vehicle);
      } else {
        setState(() {
          vehicles.add(vehicle);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, vehicle);
    }
  }

  void editVehicle(int index) {
    setState(() {
      selectedType = vehicles[index].type;
      brandController.text = vehicles[index].brand;
      modelController.text = vehicles[index].model;
      plateController.text = vehicles[index].plate;
      editingIndex = index;
      clearValidation();
    });
  }

  void deleteVehicle(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicles[index].brand} ${vehicles[index].model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                vehicles.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vehicle deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEditingMode ? 'Edit Vehicle' : 'Add Vehicle',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 6,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/car_wash_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                color: Colors.white.withOpacity(0.90),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type *',
                          prefixIcon: Icon(
                            Icons.directions_car,
                            color: typeTouched && typeError != null ? Colors.red : Colors.blue[700],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          errorText: typeTouched ? typeError : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: typeTouched && typeError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                        items: [
                          for (var type in vehicleTypes)
                            DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(getVehicleIcon(type), color: Colors.blue[700]),
                                  const SizedBox(width: 10),
                                  Text(type),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                          });
                          validateField('type');
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: brandController,
                        decoration: InputDecoration(
                          labelText: 'Brand *',
                          prefixIcon: Icon(
                            Icons.branding_watermark,
                            color: brandTouched && brandError != null ? Colors.red : Colors.blue[700],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          errorText: brandTouched ? brandError : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: brandTouched && brandError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                        onChanged: (value) => validateField('brand'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: modelController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Model * (Numbers only)',
                          prefixIcon: Icon(
                            Icons.model_training,
                            color: modelTouched && modelError != null ? Colors.red : Colors.blue[700],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          errorText: modelTouched ? modelError : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: modelTouched && modelError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                        onChanged: (value) => validateField('model'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: plateController,
                        decoration: InputDecoration(
                          labelText: 'Plate Number *',
                          prefixIcon: Icon(
                            Icons.confirmation_number,
                            color: plateTouched && plateError != null ? Colors.red : Colors.blue[700],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          errorText: plateTouched ? plateError : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: plateTouched && plateError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                        onChanged: (value) => validateField('plate'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: addVehicle,
                          icon: const Icon(Icons.save),
                          label: Text(
                            (isEditingMode || editingIndex != null) ? 'Update Vehicle' : 'Add Vehicle',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (widget.onVehicleAdded == null && widget.onVehicleUpdated == null) ...[
                if (vehicles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.directions_car_outlined, size: 80, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        const Text(
                          'No vehicles added yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Add your first vehicle above',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (vehicles.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white.withOpacity(0.9),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(
                                    getVehicleIcon(vehicles[index].type),
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${vehicles[index].type} - ${vehicles[index].brand} ${vehicles[index].model}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('Plate: ${vehicles[index].plate}'),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.local_car_wash, color: Colors.green[600]),
                                      tooltip: 'Wash this vehicle',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WashServiceScreen(
                                              vehicle: vehicles[index],
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
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.orange[700]),
                                      tooltip: 'Edit this vehicle',
                                      onPressed: () => editVehicle(index),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red[400]),
                                      tooltip: 'Delete this vehicle',
                                      onPressed: () => deleteVehicle(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
