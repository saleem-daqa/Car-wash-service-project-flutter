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

  factory Job.fromJson(Map<String, dynamic> json) {
    final scheduledAt = json['scheduled_at'];
    DateTime scheduledDate = DateTime.now();
    String scheduledTime = 'N/A';

    if (scheduledAt != null && scheduledAt.toString().isNotEmpty) {
      try {
        scheduledDate = DateTime.parse(scheduledAt);
        scheduledTime = '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        scheduledDate = DateTime.now();
        scheduledTime = 'N/A';
      }
    }

    JobStatus status = JobStatus.assigned;
    final statusStr = (json['status'] ?? 'ASSIGNED').toString().toUpperCase();
    switch (statusStr) {
      case 'ASSIGNED':
      case 'CONFIRMED':
      case 'PENDING':
        status = JobStatus.assigned;
        break;
      case 'IN_PROGRESS':
        status = JobStatus.inProgress;
        break;
      case 'COMPLETED':
        status = JobStatus.completed;
        break;
    }

    return Job(
      id: json['booking_id'].toString(),
      customerName: json['customer_name'] ?? 'Customer',
      serviceType: json['service_name'] ?? 'Service',
      vehiclePlate: json['car'] != null
          ? (json['car']['plate_number'] ?? '')
          : (json['plate_number'] ?? ''),
      latitude: json['latitude'] != null
          ? (json['latitude'] is String
              ? double.tryParse(json['latitude']) ?? 0.0
              : (json['latitude'] as num).toDouble())
          : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] is String
              ? double.tryParse(json['longitude']) ?? 0.0
              : (json['longitude'] as num).toDouble())
          : 0.0,
      addressText: json['address'] ?? json['address_text'] ?? '',
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      paymentMethod: json['payment_method'] ?? 'cash',
      status: status,
    );
  }
}
