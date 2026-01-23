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

  String getStatusText() {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.assigned:
        return 'Assigned';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}
