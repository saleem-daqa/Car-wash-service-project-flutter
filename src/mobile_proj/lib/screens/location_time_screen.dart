import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/wash_service.dart';
import 'package:geolocator/geolocator.dart';
import 'payment_selection_screen.dart';

class LocationTimeScreen extends StatefulWidget {
  final Vehicle vehicle;
  final WashService service;
  final double price;

  const LocationTimeScreen({
    super.key,
    required this.vehicle,
    required this.service,
    required this.price,
  });

  @override
  State<LocationTimeScreen> createState() => _LocationTimeScreenState();
}

class _LocationTimeScreenState extends State<LocationTimeScreen> {
  double? latitude;
  double? longitude;
  String locationStatus = 'No location selected';
  bool loadingLocation = false;
  DateTime? selectedDate;
  String? selectedTime;
  bool locationTouched = false;
  bool dateTouched = false;
  bool timeTouched = false;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool useManualAddress = false;

  Future<void> getLocation() async {
    setState(() {
      loadingLocation = true;
      locationStatus = 'Getting your location...';
      locationTouched = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          locationStatus = 'Location permission denied';
          loadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        locationStatus = 'Location set successfully';
        loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        locationStatus = 'Error: ${e.toString()}';
        loadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS location failed. You can enter address manually below.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> pickDate() async {
    setState(() {
      dateTouched = true;
    });

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    setState(() {
      timeTouched = true;
    });

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      if (picked.hour < 6 || picked.hour >= 23) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time between 6:00 AM and 11:00 PM'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        selectedTime = formatTime(picked);
      });
    }
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  bool validateFields() {
    bool isValid = true;

    if (useManualAddress) {
      if (addressController.text.trim().isEmpty) {
        setState(() {
          locationTouched = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your address'),
            backgroundColor: Colors.red,
          ),
        );
        isValid = false;
      } else {
        latitude = 31.7683;
        longitude = 35.2137;
      }
    } else if (latitude == null || longitude == null) {
      setState(() {
        locationTouched = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your location or enter address manually'),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }
    if (selectedDate == null) {
      setState(() {
        dateTouched = true;
      });
      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date'),
            backgroundColor: Colors.red,
          ),
        );
      }
      isValid = false;
    }

    if (selectedTime == null) {
      setState(() {
        timeTouched = true;
      });
      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time'),
            backgroundColor: Colors.red,
          ),
        );
      }
      isValid = false;
    }

    return isValid;
  }

  Widget buildSummaryRow(IconData icon, String label, String value, bool isPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isPrice ? 20 : 14,
                  fontWeight: isPrice ? FontWeight.bold : FontWeight.w600,
                  color: isPrice ? Colors.green[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void confirmBooking() {
    if (!validateFields()) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Booking Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      buildSummaryRow(
                        Icons.directions_car,
                        'Vehicle',
                        '${widget.vehicle.type} - ${widget.vehicle.brand} ${widget.vehicle.model}',
                        false,
                      ),
                      const Divider(height: 20),
                      buildSummaryRow(
                        Icons.confirmation_number,
                        'Plate',
                        widget.vehicle.plate,
                        false,
                      ),
                      const Divider(height: 20),
                      buildSummaryRow(
                        Icons.local_car_wash,
                        'Service',
                        widget.service.name,
                        false,
                      ),
                      const Divider(height: 20),
                      buildSummaryRow(
                        Icons.calendar_today,
                        'Date',
                        formatDate(selectedDate!),
                        false,
                      ),
                      const Divider(height: 20),
                      buildSummaryRow(
                        Icons.access_time,
                        'Time',
                        selectedTime!,
                        false,
                      ),
                      const Divider(height: 20),
                      buildSummaryRow(
                        Icons.location_on,
                        'Location',
                        useManualAddress && addressController.text.trim().isNotEmpty
                            ? addressController.text.trim()
                            : 'Lat: ${latitude!.toStringAsFixed(5)}, Lng: ${longitude!.toStringAsFixed(5)}',
                        false,
                      ),
                      const Divider(height: 20),
                      buildSummaryRow(
                        Icons.payments,
                        'Total Price',
                        '${widget.price.toStringAsFixed(2)} ₪',
                        true,
                      ),
                      if (notesController.text.trim().isNotEmpty) ...[
                        const Divider(height: 20),
                        buildSummaryRow(
                          Icons.note_alt,
                          'Notes',
                          notesController.text.trim(),
                          false,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentSelectionScreen(
                                bookingAmount: widget.price,
                                bookingId: 123,
                                serviceName: widget.service.name,
                                vehicle: widget.vehicle,
                                latitude: latitude!,
                                longitude: longitude!,
                                scheduledDate: selectedDate!,
                                scheduledTime: selectedTime!,
                                notes: notesController.text.trim(),
                                addressText: addressController.text.trim(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Continue to Payment'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Location & Time',
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/car_wash_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                color: Colors.white.withOpacity(0.92),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: locationTouched && latitude == null && !useManualAddress
                      ? const BorderSide(color: Colors.red, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locationStatus,
                        style: TextStyle(
                          color: locationTouched && latitude == null && !useManualAddress ? Colors.red : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loadingLocation ? null : getLocation,
                          icon: loadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, color: Colors.white),
                          label: Text(
                            loadingLocation ? 'Getting Location...' : 'Use Current Location',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      if (latitude != null && longitude != null && !useManualAddress)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Lat: ${latitude!.toStringAsFixed(5)}, Lng: ${longitude!.toStringAsFixed(5)}',
                                    style: TextStyle(fontSize: 12, color: Colors.green[900]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Enter Address Manually',
                          hintText: 'e.g., 123 Main Street, City',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              useManualAddress = true;
                              locationTouched = true;
                            });
                          } else {
                            setState(() {
                              useManualAddress = false;
                            });
                          }
                        },
                      ),
                      if (useManualAddress && addressController.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.blue[700], size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    addressController.text.trim(),
                                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white.withOpacity(0.92),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: dateTouched && selectedDate == null
                      ? const BorderSide(color: Colors.red, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dateTouched && selectedDate == null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: dateTouched && selectedDate == null
                                    ? Colors.red
                                    : Colors.blue[700],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedDate == null ? 'Select a date' : formatDate(selectedDate!),
                                style: TextStyle(
                                  color: dateTouched && selectedDate == null
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white.withOpacity(0.92),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: timeTouched && selectedTime == null
                      ? const BorderSide(color: Colors.red, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: timeTouched && selectedTime == null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: timeTouched && selectedTime == null
                                    ? Colors.red
                                    : Colors.blue[700],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedTime ?? 'Select a time',
                                style: TextStyle(
                                  color: timeTouched && selectedTime == null
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Our working hours are from 6:00 AM to 11:00 PM',
                                style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white.withOpacity(0.92),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any special instructions? (gate code, parking, etc)',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: confirmBooking,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Confirm Booking', style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
