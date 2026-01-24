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
  return Booking(
    id: 'JOB-${json['id']}',
    vehiclePlate: json['vehicle_plate'],
    serviceName: json['service_name'],
    price: double.parse(json['price'].toString()),
    scheduledDate: DateTime.parse(json['booking_date']),
    scheduledTime: json['booking_time'],
    latitude: 0,
    longitude: 0,
    paymentMethod: '',
    status: BookingStatusExtension.fromString(json['status']),
  );
}
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
extension BookingStatusExtension on BookingStatus {
static BookingStatus fromString(String status) {
switch (status.toUpperCase()) {
case 'PENDING':
return BookingStatus.pending;
case 'CONFIRMED':
return BookingStatus.confirmed;
case 'ASSIGNED':
return BookingStatus.assigned;
case 'IN_PROGRESS':
return BookingStatus.inProgress;
case 'COMPLETED':
return BookingStatus.completed;
case 'CANCELLED':
return BookingStatus.cancelled;
default:
return BookingStatus.pending;
}
}
}