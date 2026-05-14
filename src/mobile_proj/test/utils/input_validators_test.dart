import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_proj/utils/input_validators.dart';

void main() {
  group('InputValidators', () {
    test('accepts valid email addresses', () {
      expect(InputValidators.email('saleem@example.com'), isNull);
      expect(InputValidators.email('student.name+test@university.edu'), isNull);
    });

    test('rejects blank or malformed email addresses', () {
      expect(InputValidators.email(''), isNotNull);
      expect(InputValidators.email('saleem'), isNotNull);
      expect(InputValidators.email('saleem@example'), isNotNull);
    });

    test('requires a strong enough password', () {
      expect(InputValidators.password('manager123'), isNull);
      expect(InputValidators.password('12345678'), isNotNull);
      expect(InputValidators.password('password'), isNotNull);
      expect(InputValidators.password('abc12'), isNotNull);
    });

    test('validates matching password confirmation', () {
      expect(
        InputValidators.confirmPassword('manager123', 'manager123'),
        isNull,
      );
      expect(
        InputValidators.confirmPassword('manager123', 'manager124'),
        isNotNull,
      );
    });

    test('validates phone numbers with at least eight digits', () {
      expect(InputValidators.phone('+970 59 123 4567'), isNull);
      expect(InputValidators.phone('1234567'), isNotNull);
      expect(InputValidators.phone('phone-number'), isNotNull);
    });

    test('validates vehicle fields', () {
      expect(InputValidators.vehicleBrand('Toyota'), isNull);
      expect(InputValidators.vehicleModel('Corolla'), isNull);
      expect(InputValidators.vehiclePlate('ABC-123'), isNull);
      expect(InputValidators.vehicleBrand('A'), isNotNull);
      expect(InputValidators.vehicleModel(''), isNotNull);
      expect(InputValidators.vehiclePlate('1'), isNotNull);
    });
  });
}
