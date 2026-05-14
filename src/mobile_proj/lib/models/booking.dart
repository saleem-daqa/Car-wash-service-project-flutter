enum BookingStatus {
  pending,
  confirmed,
  assigned,
  inProgress,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String vehiclePlate;
  final String serviceName;
  final double price;
  final DateTime scheduledDate;
  final String scheduledTime;
  final double latitude;
  final double longitude;
  final String? notes;
  final String paymentMethod;
  BookingStatus status;

  Booking({
    required this.id,
    required this.vehiclePlate,
    required this.serviceName,
    required this.price,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.latitude,
    required this.longitude,
    this.notes,
    required this.paymentMethod,
    this.status = BookingStatus.pending,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime scheduledDate = DateTime.now();
    String scheduledTime = 'N/A';

    if (json['booking_date'] != null) {
      try {
        if (json['booking_time'] != null) {
          final dateStr = json['booking_date'].toString();
          final timeStr = json['booking_time'].toString();
          scheduledDate = DateTime.parse('$dateStr $timeStr:00');
          scheduledTime = timeStr;
        } else {
          scheduledDate = DateTime.parse(json['booking_date'].toString());
          scheduledTime =
              '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        scheduledDate = DateTime.now();
        scheduledTime = 'N/A';
      }
    }

    BookingStatus status = BookingStatus.pending;
    final statusStr = (json['status'] ?? 'PENDING').toString().toUpperCase();
    switch (statusStr) {
      case 'PENDING':
        status = BookingStatus.pending;
        break;
      case 'CONFIRMED':
        status = BookingStatus.confirmed;
        break;
      case 'ASSIGNED':
        status = BookingStatus.assigned;
        break;
      case 'IN_PROGRESS':
        status = BookingStatus.inProgress;
        break;
      case 'COMPLETED':
        status = BookingStatus.completed;
        break;
      case 'CANCELLED':
        status = BookingStatus.cancelled;
        break;
    }

    return Booking(
      id: 'JOB-${json['id'] ?? json['booking_id']}',
      vehiclePlate: json['vehicle_plate'] ?? '',
      serviceName: json['service_name'] ?? 'Service',
      price: (json['price'] ?? 0.0).toDouble(),
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      latitude: 0.0,
      longitude: 0.0,
      paymentMethod: 'cash',
      status: status,
    );
  }
}
