import '../config/api_config.dart';
import '../utils/input_validators.dart';
import 'api_client.dart';

enum UserRole { customer, employee, manager, unknown }

class UserSession {
  final int userId;
  final UserRole role;
  final String? name;
  final String? email;
  final String? phone;

  const UserSession({
    required this.userId,
    required this.role,
    this.name,
    this.email,
    this.phone,
  });
}

class AuthService {
  final ApiClient _apiClient;
  final Uri _loginUri;
  final Uri _registerUri;
  final Uri _verifyPasswordUri;
  final Uri _changePasswordUri;

  AuthService({
    ApiClient? apiClient,
    Uri? loginUri,
    Uri? registerUri,
    Uri? verifyPasswordUri,
    Uri? changePasswordUri,
  }) : _apiClient = apiClient ?? ApiClient(),
       _loginUri = loginUri ?? Uri.parse(ApiConfig.loginUrl),
       _registerUri = registerUri ?? Uri.parse(ApiConfig.registerUrl),
       _verifyPasswordUri =
           verifyPasswordUri ?? Uri.parse(ApiConfig.verifyPasswordUrl),
       _changePasswordUri =
           changePasswordUri ?? Uri.parse(ApiConfig.changePasswordUrl);

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final emailError = InputValidators.email(normalizedEmail);
    if (emailError != null || password.isEmpty) {
      throw const ApiException('Please enter a valid email and password.');
    }

    final data = await _apiClient.postForm(
      _loginUri,
      body: {'email': normalizedEmail, 'password': password},
    );

    if (!_isSuccess(data)) {
      throw ApiException(
        _serverMessage(data, fallback: 'Invalid email or password.'),
      );
    }

    final userId = _asInt(
      data['user_id'] ?? data['data']?['user_id'] ?? data['user']?['id'],
    );
    if (userId == null) {
      throw const ApiException('Login succeeded but user data was incomplete.');
    }

    final user = data['user'];
    return UserSession(
      userId: userId,
      role: _roleFromString((data['role'] ?? data['data']?['role']).toString()),
      name: user is Map ? user['name']?.toString() : null,
      email: user is Map ? user['email']?.toString() : normalizedEmail,
      phone: user is Map ? user['phone']?.toString() : null,
    );
  }

  Future<int> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final errors = [
      InputValidators.fullName(fullName),
      InputValidators.email(email),
      InputValidators.phone(phone),
      InputValidators.password(password),
    ].whereType<String>().toList();

    if (errors.isNotEmpty) {
      throw ApiException(errors.first);
    }

    final data = await _apiClient.postJson(
      _registerUri,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
      },
    );

    if (!_isSuccess(data)) {
      throw ApiException(_serverMessage(data, fallback: 'Could not register.'));
    }

    final userId = _asInt(data['user_id'] ?? data['data']?['user_id']);
    if (userId == null) {
      throw const ApiException(
        'Registered, but the server did not return a user ID.',
      );
    }

    return userId;
  }

  Future<bool> verifyPassword({
    required int userId,
    required String password,
  }) async {
    if (userId <= 0 || password.isEmpty) return false;

    final data = await _apiClient.postForm(
      _verifyPasswordUri,
      body: {'user_id': userId.toString(), 'password': password},
    );

    return _isSuccess(data);
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final passwordError = InputValidators.password(newPassword);
    if (userId <= 0 || currentPassword.isEmpty || passwordError != null) {
      throw ApiException(passwordError ?? 'Missing password fields.');
    }

    final data = await _apiClient.postForm(
      _changePasswordUri,
      body: {
        'user_id': userId.toString(),
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (!_isSuccess(data)) {
      throw ApiException(
        _serverMessage(data, fallback: 'Could not change password.'),
      );
    }
  }

  bool _isSuccess(Map<String, dynamic> data) {
    return data['ok'] == true ||
        data['status']?.toString().toLowerCase() == 'success';
  }

  String _serverMessage(Map<String, dynamic> data, {required String fallback}) {
    final message = data['error'] ?? data['message'];
    return message?.toString().trim().isNotEmpty == true
        ? message.toString()
        : fallback;
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  UserRole _roleFromString(String role) {
    switch (role.toUpperCase()) {
      case 'CUSTOMER':
        return UserRole.customer;
      case 'EMPLOYEE':
        return UserRole.employee;
      case 'MANAGER':
        return UserRole.manager;
      default:
        return UserRole.unknown;
    }
  }
}
