import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_proj/services/api_client.dart';
import 'package:mobile_proj/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('logs in with normalized email and returns a session', () async {
      late http.Request capturedRequest;
      final authService = AuthService(
        apiClient: ApiClient(
          httpClient: MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              '{"status":"success","user_id":7,"role":"customer","user":{"name":"Saleem"}}',
              200,
            );
          }),
        ),
        loginUri: Uri.parse('https://example.com/login.php'),
      );

      final session = await authService.login(
        email: ' Saleem@Example.COM ',
        password: 'manager123',
      );

      expect(session.userId, 7);
      expect(session.role, UserRole.customer);
      expect(session.name, 'Saleem');
      expect(capturedRequest.bodyFields['email'], 'saleem@example.com');
      expect(capturedRequest.bodyFields['password'], 'manager123');
    });

    test('rejects invalid login input before calling the API', () async {
      var called = false;
      final authService = AuthService(
        apiClient: ApiClient(
          httpClient: MockClient((_) async {
            called = true;
            return http.Response('{}', 200);
          }),
        ),
      );

      await expectLater(
        authService.login(email: 'bad-email', password: ''),
        throwsA(isA<ApiException>()),
      );
      expect(called, isFalse);
    });

    test(
      'reads user id from both legacy and ok/data register responses',
      () async {
        final legacyService = AuthService(
          apiClient: ApiClient(
            httpClient: MockClient((_) async {
              return http.Response('{"status":"success","user_id":12}', 200);
            }),
          ),
          registerUri: Uri.parse('https://example.com/register.php'),
        );
        final modernService = AuthService(
          apiClient: ApiClient(
            httpClient: MockClient((_) async {
              return http.Response('{"ok":true,"data":{"user_id":13}}', 200);
            }),
          ),
          registerUri: Uri.parse('https://example.com/register.php'),
        );

        expect(
          await legacyService.register(
            fullName: 'Saleem Daqa',
            email: 'saleem@example.com',
            phone: '+970591234567',
            password: 'manager123',
          ),
          12,
        );
        expect(
          await modernService.register(
            fullName: 'Saleem Daqa',
            email: 'saleem@example.com',
            phone: '+970591234567',
            password: 'manager123',
          ),
          13,
        );
      },
    );
  });
}
