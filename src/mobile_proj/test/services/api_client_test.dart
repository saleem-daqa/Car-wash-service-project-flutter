import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_proj/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('decodes successful JSON responses', () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => http.Response('{"status":"success","value":42}', 200),
        ),
      );

      final data = await client.postForm(
        Uri.parse('https://example.com/login.php'),
        body: {'email': 'saleem@example.com'},
      );

      expect(data['status'], 'success');
      expect(data['value'], 42);
    });

    test('throws a safe message for non-success status codes', () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => http.Response('{"message":"SQL stack trace"}', 500),
        ),
      );

      expect(
        () => client.postForm(Uri.parse('https://example.com/login.php')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                'Server error. Please try again later.',
              ),
        ),
      );
    });

    test('throws a clear message for invalid JSON', () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => http.Response('<html>Not JSON</html>', 200),
        ),
      );

      expect(
        () => client.getJson(Uri.parse('https://example.com/login.php')),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid server response. Please try again later.',
          ),
        ),
      );
    });
  });
}
