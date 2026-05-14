import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/vehicle.dart';
import '../utils/input_validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_text_field.dart';

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

  final List<String> vehicleTypes = const [
    'Car/Sedan',
    'Bus/Truck',
    'Motorcycle/Scooter',
  ];
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Please log in before saving a vehicle.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.vehicleToEdit != null;
      final url = isEditing
          ? ApiConfig.updateVehicleUrl
          : ApiConfig.createVehicleUrl;

      final body = {
        'customer_id': customerId.toString(),
        'plate_number': plateController.text.trim().toUpperCase(),
        'type': selectedType ?? vehicleTypes.first,
        'car_brand': brandController.text.trim(),
        'car_model': modelController.text.trim(),
        'color': '',
        'notes': '',
      };

      if (isEditing && widget.vehicleToEdit!.carId != null) {
        body['car_id'] = widget.vehicleToEdit!.carId.toString();
      }

      final response = await http.post(Uri.parse(url), body: body);

      if (!mounted) return;

      final responseBody = response.body.trim();
      if (responseBody.isEmpty || !responseBody.startsWith('{')) {
        showAppSnackBar(
          context,
          message: 'Server error. Please try again.',
          isError: true,
        );
        return;
      }

      final data = json.decode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'success') {
        final vehicle = Vehicle(
          type: selectedType!,
          brand: brandController.text.trim(),
          model: modelController.text.trim(),
          plate: plateController.text.trim().toUpperCase(),
          carId: isEditing ? widget.vehicleToEdit!.carId : data['car_id'],
        );

        if (isEditing) {
          widget.onVehicleUpdated?.call(vehicle);
          showAppSnackBar(context, message: 'Vehicle updated successfully.');
        } else {
          widget.onVehicleAdded?.call(vehicle);
          showAppSnackBar(context, message: 'Vehicle added successfully.');
        }
        Navigator.pop(context);
      } else {
        showAppSnackBar(
          context,
          message: data['message']?.toString() ?? 'Could not save vehicle.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Could not save vehicle. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicleToEdit != null;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text(isEditing ? 'Edit vehicle' : 'Add vehicle'),
      ),
      body: AppShell(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Update vehicle details' : 'Add a vehicle',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                isEditing
                    ? 'Keep your car information accurate for service teams.'
                    : 'Add the vehicle you want to book services for.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Vehicle type',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                          hintText: 'Choose vehicle type',
                        ),
                        items: vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) => setState(() => selectedType = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a vehicle type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Brand',
                        hintText: 'Toyota',
                        controller: brandController,
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icons.directions_car_outlined,
                        validator: InputValidators.vehicleBrand,
                      ),
                      AppTextField(
                        label: 'Model',
                        hintText: 'Corolla',
                        controller: modelController,
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icons.local_car_wash_outlined,
                        validator: InputValidators.vehicleModel,
                      ),
                      AppTextField(
                        label: 'Plate number',
                        hintText: '123-456',
                        controller: plateController,
                        textCapitalization: TextCapitalization.characters,
                        prefixIcon: Icons.confirmation_number_outlined,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9\-\s]'),
                          ),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: InputValidators.vehiclePlate,
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: isEditing ? 'Update vehicle' : 'Add vehicle',
                        icon: isEditing ? Icons.save_outlined : Icons.add,
                        isLoading: _isLoading,
                        onPressed: saveVehicle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
