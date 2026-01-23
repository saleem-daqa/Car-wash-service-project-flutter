import '../models/booking.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  double balance = 0.00;
  int points = 0;
  static const double pointsToNisRate = 0.2;

  void addPoints(int pointsToAdd) {
    points = points + pointsToAdd;
  }

  void convertPointsToNis() {
    if (points == 0) return;
    double nisAmount = points * pointsToNisRate;
    balance = balance + nisAmount;
    points = 0;
  }

  int calculatePointsFromService(String serviceName) {
    switch (serviceName) {
      case 'Basic Wash':
        return 1;
      case 'Deluxe Wash':
        return 2;
      case 'Premium Wash':
        return 3;
      default:
        return 1;
    }
  }

  void addPointsFromCompletedService(String serviceName) {
    int pointsEarned = calculatePointsFromService(serviceName);
    addPoints(pointsEarned);
  }
}
