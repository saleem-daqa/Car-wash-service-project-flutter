import '../models/booking.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final List<Booking> _bookings = [];
  List<Booking>? _currentBookings;
  List<Booking>? _pastBookings;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  void addBooking(Booking booking) {
    _bookings.add(booking);
  }

  void updateBookingStatus(String bookingId, BookingStatus newStatus) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].status = newStatus;
    }
    _currentBookings = null;
    _pastBookings = null;
  }

  Future<List<Booking>> fetchCurrentBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id') ?? 0;

      if (customerId == 0) {
        return [];
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getCurrentBookingsUrl),
        body: {'user_id': customerId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['bookings'] != null) {
          final bookings = (data['bookings'] as List).map((bookingData) {
            return _mapBookingFromNewApi(bookingData);
          }).toList();
          _currentBookings = bookings;
          return bookings;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Booking>> fetchPastBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id') ?? 0;

      if (customerId == 0) {
        return [];
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getPastBookingsUrl),
        body: {'user_id': customerId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['bookings'] != null) {
          final bookings = (data['bookings'] as List).map((bookingData) {
            return _mapBookingFromNewApi(bookingData);
          }).toList();
          _pastBookings = bookings;
          return bookings;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int> createBooking({
    required int customerId,
    required int carId,
    required String serviceName,
    required double price,
    required String bookingDate,
    required String bookingTime,
    required double latitude,
    required double longitude,
    required String paymentMethod,
    String? addressText,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createBookingUrl),
        body: {
          'customer_id': customerId.toString(),
          'car_id': carId.toString(),
          'service_name': serviceName,
          'price': price.toString(),
          'booking_date': bookingDate,
          'booking_time': bookingTime,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'payment_method': paymentMethod,
          'address_text': addressText ?? '',
          'notes': notes ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['booking_id'] != null) {
          return data['booking_id'] as int;
        }
        throw Exception(data['message'] ?? 'Failed to create booking');
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  List<Booking> getCurrentBookings() {
    return _currentBookings ??
        _bookings
            .where(
              (b) =>
                  b.status != BookingStatus.completed &&
                  b.status != BookingStatus.cancelled,
            )
            .toList();
  }

  List<Booking> getPastBookings() {
    return _pastBookings ??
        _bookings
            .where(
              (b) =>
                  b.status == BookingStatus.completed ||
                  b.status == BookingStatus.cancelled,
            )
            .toList();
  }

  Booking _mapBookingFromNewApi(Map<String, dynamic> bookingData) {
    DateTime scheduledDate = DateTime.now();
    String scheduledTime = 'N/A';

    if (bookingData['booking_date'] != null) {
      try {
        if (bookingData['booking_time'] != null) {
          final dateStr = bookingData['booking_date'].toString();
          final timeStr = bookingData['booking_time'].toString();
          scheduledDate = DateTime.parse('$dateStr $timeStr:00');
          scheduledTime = timeStr;
        } else {
          scheduledDate = DateTime.parse(
            bookingData['booking_date'].toString(),
          );
          scheduledTime =
              '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        scheduledDate = DateTime.now();
        scheduledTime = 'N/A';
      }
    }

    return Booking(
      id: 'JOB-${bookingData['id']}',
      vehiclePlate: bookingData['vehicle_plate'] ?? '',
      serviceName: bookingData['service_name'] ?? 'Service',
      price: (bookingData['price'] ?? 0.0).toDouble(),
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      latitude: 0.0,
      longitude: 0.0,
      paymentMethod: 'cash',
      status: _mapStatusFromApi(bookingData['status'] ?? 'PENDING'),
    );
  }

  BookingStatus _mapStatusFromApi(String apiStatus) {
    switch (apiStatus.toUpperCase()) {
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
