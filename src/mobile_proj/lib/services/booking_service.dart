import '../models/booking.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final List<Booking> _bookings = [];

  List<Booking> get bookings => List.unmodifiable(_bookings);

  void addBooking(Booking booking) {
    _bookings.add(booking);
  }

  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = newStatus;
    }
  }

  List<Booking> getCurrentBookings() {
    return _bookings.where((b) => 
      b.status != BookingStatus.completed && 
      b.status != BookingStatus.cancelled
    ).toList();
  }

  List<Booking> getPastBookings() {
    return _bookings.where((b) => 
      b.status == BookingStatus.completed || 
      b.status == BookingStatus.cancelled
    ).toList();
  }
}
