import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ServicesManagementScreen extends StatefulWidget {
  const ServicesManagementScreen({super.key});

  @override
  State<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends State<ServicesManagementScreen> {
  Future<List<dynamic>>? servicesFuture;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  void loadServices() {
    setState(() {
      servicesFuture = fetchServices();
    });
  }

  Future<List<dynamic>> fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/services_list_all.php'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['services'] ?? [];
        } else if (data['ok'] == true && data['data'] != null) {
          return data['data']['services'] ?? [];
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<void> deleteService(int serviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
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
        Uri.parse(ApiConfig.servicesDeleteUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'service_id': serviceId}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true || data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          loadServices();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['error'] ?? data['message'] ?? 'Could not delete',
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
                data['error'] ?? data['message'] ?? 'Could not delete',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void editService(Map<String, dynamic> service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(
          service: service,
          onSaved: () => loadServices(),
        ),
      ),
    );
  }

  void addService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(onSaved: () => loadServices()),
      ),
    );
  }

  Future<void> createDefaultServices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/create_default_services.php'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Default services created: ${(data['created'] ?? []).join(', ')}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          loadServices();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to create'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services Management')),
      body: RefreshIndicator(
        onRefresh: () async {
          loadServices();
          await servicesFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: servicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final services = snapshot.data ?? [];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: addService,
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (services.isEmpty) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: createDefaultServices,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Create Default'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: services.isEmpty
                      ? const Center(child: Text('No services available'))
                      : ListView.builder(
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  _getServiceIcon(service['name'] ?? ''),
                                  color: _getServiceColor(
                                    service['name'] ?? '',
                                  ),
                                ),
                                title: Text(
                                  service['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (service['description'] != null &&
                                        service['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          service['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    Text(
                                      'Price: ${(double.tryParse((service['price'] ?? 0).toString()) ?? 0.0).toStringAsFixed(2)} ₪ | Duration: ${service['duration_minutes'] ?? 0} min | Status: ${service['is_active'] == 1 ? 'Active' : 'Inactive'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
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
                                      onPressed: () => editService(service),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => deleteService(
                                        int.tryParse(
                                              service['service_id'].toString(),
                                            ) ??
                                            0,
                                      ),
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

  IconData _getServiceIcon(String name) {
    if (name.toLowerCase().contains('basic')) return Icons.local_car_wash;
    if (name.toLowerCase().contains('deluxe')) return Icons.cleaning_services;
    if (name.toLowerCase().contains('premium')) return Icons.star;
    return Icons.local_car_wash;
  }

  Color _getServiceColor(String name) {
    if (name.toLowerCase().contains('basic')) return Colors.blue;
    if (name.toLowerCase().contains('deluxe')) return Colors.orange;
    if (name.toLowerCase().contains('premium')) return Colors.purple;
    return Colors.blue;
  }
}

class AddEditServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? service;

  final VoidCallback onSaved;

  const AddEditServiceScreen({super.key, this.service, required this.onSaved});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!['name'] ?? '';
      _descriptionController.text = widget.service!['description'] ?? '';
      final price = widget.service!['price'];
      _priceController.text = price != null
          ? (double.tryParse(price.toString()) ?? 0.0).toStringAsFixed(2)
          : '0.00';
      _durationController.text = (widget.service!['duration_minutes'] ?? 30)
          .toString();
      _isActive = (widget.service!['is_active'] ?? 1) == 1;
    } else {
      _durationController.text = '30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final body = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'duration_minutes': int.parse(_durationController.text),
        'is_active': _isActive ? 1 : 0,
      };

      if (widget.service != null) {
        body['service_id'] = widget.service!['service_id'];
        final response = await http.put(
          Uri.parse(ApiConfig.servicesUpdateUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (!mounted) return;
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service updated successfully'),
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
          Uri.parse(ApiConfig.servicesCreateUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (!mounted) return;
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['ok'] == true || data['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service created successfully'),
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
                  'Failed to create service: ${response.statusCode}',
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
        title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  prefixIcon: Icon(Icons.local_car_wash),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₪)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Invalid number';
                  if (double.parse(v) < 0) return 'Must be >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  if (int.tryParse(v!) == null) return 'Invalid number';
                  if (int.parse(v) <= 0) return 'Must be > 0';
                  return null;
                },
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
                  onPressed: _isLoading ? null : saveService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.service == null
                              ? 'Create Service'
                              : 'Update Service',
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
