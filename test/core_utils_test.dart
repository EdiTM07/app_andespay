import 'package:flutter_test/flutter_test.dart';
import 'package:app_banco/core/utils/formatters.dart';
import 'package:app_banco/core/utils/security_helpers.dart';
import 'package:app_banco/core/utils/validators.dart';

void main() {
  group('AppFormatters', () {
    test('currency formats correctly', () {
      expect(AppFormatters.currency(1234.56), equals('\$1.234,56'));
    });

    test('accountNumber formats correctly', () {
      expect(AppFormatters.accountNumber('1234567890'), equals('1234-5678-90'));
      // Si la cuenta no tiene 10 dígitos, debe devolver el mismo string
      expect(AppFormatters.accountNumber('123'), equals('123'));
    });
  });

  group('SecurityHelpers', () {
    test('hashPin generates consistent hashes', () {
      final hash1 = SecurityHelpers.hashPin('1234');
      final hash2 = SecurityHelpers.hashPin('1234');
      expect(hash1, equals(hash2));
    });

    test('verifyPin validates correctly', () {
      final hash = SecurityHelpers.hashPin('9876');
      expect(SecurityHelpers.verifyPin('9876', hash), isTrue);
      expect(SecurityHelpers.verifyPin('0000', hash), isFalse);
    });
  });

  group('AppValidators', () {
    test('email validator', () {
      expect(AppValidators.email(''), isNotNull); // Error
      expect(AppValidators.email('invalid-email'), isNotNull); // Error
      expect(AppValidators.email('test@andespay.ec'), isNull); // Valid
    });

    test('pin validator', () {
      expect(AppValidators.pin('123'), isNotNull); // Error
      expect(AppValidators.pin('1234a'), isNotNull); // Error
      expect(AppValidators.pin('1234'), isNull); // Valid
    });
  });
}
