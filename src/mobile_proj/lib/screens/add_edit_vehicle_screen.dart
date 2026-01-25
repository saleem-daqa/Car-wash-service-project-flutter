import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vehicle.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  final List<String> vehicleTypes = ['Car/Sedan', 'Bus/Truck', 'Motorcycle/Scooter'];
  String? selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleToEdit != null) {
      selectedType = widget.vehicleToEdit!.type;
      brandController.text = widget.vehicleToEdit!.brand;
      modelController.text = widget.vehicleToEdit!.model;
      plateController.text = widget.vehicleToEdit!.plate;
    }
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    plateController.dispose();
    super.dispose();
  }

  Future<void> saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.vehicleToEdit != null;
      final url = isEditing ? ApiConfig.updateVehicleUrl : ApiConfig.createVehicleUrl;

      final body = {
        'customer_id': customerId.toString(),
        'plate_number': plateController.text.trim().toUpperCase(),
        'type': selectedType ?? 'Car/Sedan',
        'car_brand': brandController.text.trim(),
        'car_model': modelController.text.trim(),
        'color': '',
        'notes': '',
        'type': selectedType!,
      };

      if (isEditing && widget.vehicleToEdit!.carId != null) {
        body['car_id'] = widget.vehicleToEdit!.carId.toString();
      }

      final response = await http.post(
        Uri.parse(url),
        body: body,
      );

      if (!mounted) return;

      final responseBody = response.body.trim();
      if (responseBody.isEmpty || !responseBody.startsWith('{')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error, please try again'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = json.decode(responseBody);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final vehicle = Vehicle(
          type: selectedType!,
          brand: brandController.text.trim(),
          model: modelController.text.trim(),
          plate: plateController.text.trim().toUpperCase(),
          carId: isEditing ? widget.vehicleToEdit!.carId : data['car_id'],
        );

        if (isEditing) {
          if (widget.onVehicleUpdated != null) {
            widget.onVehicleUpdated!(vehicle);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (widget.onVehicleAdded != null) {
            widget.onVehicleAdded!(vehicle);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Could not save vehicle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicleToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
        title: Text(
          isEditing ? 'Edit Vehicle' : 'Add Vehicle',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          width: double.infinity,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Edit your vehicle' : 'Add a new vehicle',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Type *',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
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
                          items: vehicleTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a vehicle type';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                buildInputField(
                  label: 'Brand *',
                  controller: brandController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the vehicle brand';
                    }
                    if (!Vehicle.isValidBrand(value.trim())) {
                      return 'Brand must be between 2 and 50 characters';
                    }
                    return null;
                  },
                ),
                buildInputField(
                  label: 'Model * (Numbers only)',
                  controller: modelController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the vehicle model';
                    }
                    if (!Vehicle.isValidModel(value.trim())) {
                      return 'Model must contain only numbers';
                    }
                    return null;
                  },
                ),
                buildInputField(
                  label: 'Plate Number *',
                  controller: plateController,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the plate number';
                    }
                    if (!Vehicle.isValidPlate(value.trim())) {
                      return 'Plate number must be between 3 and 15 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : saveVehicle,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: const Color(0xff0095FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Vehicle' : 'Add Vehicle',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
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
