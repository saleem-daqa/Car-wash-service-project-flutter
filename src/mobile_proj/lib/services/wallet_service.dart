import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  static const double pointsToNisRate = 0.2;

  double balance = 0.00;
  int points = 0;

  Future<void> loadWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id') ?? 0;

      if (customerId == 0) return;

      final response = await http.post(
        Uri.parse(ApiConfig.getWalletUrl),
        body: {'customer_id': customerId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          balance = (data['balance'] ?? 0.0).toDouble();
          points = (data['points'] ?? 0) as int;
        }
      }
    } catch (e) {
      balance = 0.00;
      points = 0;
    }
  }

  Future<bool> convertPointsToNis() async {
    if (points == 0) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id') ?? 0;

      if (customerId == 0) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.convertPointsUrl),
        body: {'customer_id': customerId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          balance = (data['new_balance'] ?? balance).toDouble();
          points = 0;
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

}
