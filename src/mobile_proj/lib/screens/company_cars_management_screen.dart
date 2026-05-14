import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CompanyCarsManagementScreen extends StatefulWidget {
  const CompanyCarsManagementScreen({super.key});

  @override
  State<CompanyCarsManagementScreen> createState() =>
      _CompanyCarsManagementScreenState();
}

class _CompanyCarsManagementScreenState
    extends State<CompanyCarsManagementScreen> {
  Future<List<dynamic>>? carsFuture;

  @override
  void initState() {
    super.initState();
    loadCars();
  }

  void loadCars() {
    setState(() {
      carsFuture = fetchCars();
    });
  }

  Future<List<dynamic>> fetchCars() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/company_cars_list.php'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['cars'] ?? [];
    }
    return [];
  }

  Future<void> deleteCar(int carId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company Car'),
        content: const Text(
          'Are you sure you want to delete this company car?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/company_cars_delete.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'company_car_id': carId}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company car deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          loadCars();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Could not delete'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void editCar(Map<String, dynamic> car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditCompanyCarScreen(car: car, onSaved: () => loadCars()),
      ),
    );
  }

  void addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCompanyCarScreen(onSaved: () => loadCars()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Cars Management')),
      body: RefreshIndicator(
        onRefresh: () async {
          loadCars();
          await carsFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: carsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final cars = snapshot.data ?? [];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: addCar,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Company Car'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: cars.isEmpty
                      ? const Center(child: Text('No company cars available'))
                      : ListView.builder(
                          itemCount: cars.length,
                          itemBuilder: (context, index) {
                            final car = cars[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.directions_car,
                                  color: AppTheme.primaryBlue,
                                ),
                                title: Text(
                                  car['model'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Plate: ${car['plate_number'] ?? 'N/A'}',
                                    ),
                                    Text(
                                      'Status: ${car['is_active'] == 1 ? 'Active' : 'Inactive'}',
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      onPressed: () => editCar(car),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          deleteCar(car['company_car_id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AddEditCompanyCarScreen extends StatefulWidget {
  final Map<String, dynamic>? car;
  final VoidCallback onSaved;

  const AddEditCompanyCarScreen({super.key, this.car, required this.onSaved});

  @override
  State<AddEditCompanyCarScreen> createState() =>
      _AddEditCompanyCarScreenState();
}

class _AddEditCompanyCarScreenState extends State<AddEditCompanyCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) {
      _plateController.text = widget.car!['plate_number'] ?? '';
      _modelController.text = widget.car!['model'] ?? '';
      _isActive = (widget.car!['is_active'] ?? 1) == 1;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final body = {
        'plate_number': _plateController.text.trim(),
        'model': _modelController.text.trim(),
        'is_active': _isActive ? 1 : 0,
      };

      if (widget.car != null) {
        body['company_car_id'] = widget.car!['company_car_id'];
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/company_cars_update.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (!mounted) return;
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Company car updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
            widget.onSaved();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? 'Failed to update'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/company_cars_create.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (!mounted) return;
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['ok'] == true || data['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Company car created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
            widget.onSaved();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['error'] ?? data['message'] ?? 'Failed to create',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          try {
            final data = json.decode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['error'] ?? data['message'] ?? 'Failed to create',
                ),
                backgroundColor: Colors.red,
              ),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to create company car: ${response.statusCode}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.car == null ? 'Add Company Car' : 'Edit Company Car',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveCar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.car == null ? 'Create Car' : 'Update Car'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
