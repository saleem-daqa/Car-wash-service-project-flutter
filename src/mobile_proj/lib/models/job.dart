enum JobStatus {
  assigned,
  inProgress,
  completed,
}

class Job {
  final String id;
  final String customerName;
  final String serviceType;
  final String vehiclePlate;
  final double latitude;
  final double longitude;
  final String? addressText;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String? notes;
  final String paymentMethod;
  JobStatus status;

  Job({
    required this.id,
    required this.customerName,
    required this.serviceType,
    required this.vehiclePlate,
    required this.latitude,
    required this.longitude,
    this.addressText,
    required this.scheduledDate,
    required this.scheduledTime,
    this.notes,
    required this.paymentMethod,
    this.status = JobStatus.assigned,
  });

  String getLocationString() {
    if (addressText != null && addressText!.isNotEmpty) {
      return addressText!;
    }
    return 'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}';
  }
}
