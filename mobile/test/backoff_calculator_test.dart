import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/core/sync/backoff_calculator.dart';

void main() {
  group('ExponentialBackoff Tests', () {
    test('Calcula retrasos con crecimiento exponencial dentro de límites', () {
      final delay1 = ExponentialBackoff.calculateDelay(1);
      final delay2 = ExponentialBackoff.calculateDelay(2);
      final delay5 = ExponentialBackoff.calculateDelay(5);
      final delay10 = ExponentialBackoff.calculateDelay(10);

      expect(delay1.inSeconds, inInclusiveRange(3, 7)); // ~5s ± 20%
      expect(delay2.inSeconds, inInclusiveRange(7, 13)); // ~10s ± 20%
      expect(delay5.inSeconds, inInclusiveRange(60, 100)); // ~80s ± 20%
      expect(delay10.inSeconds, lessThanOrEqualTo(150)); // Max cap 120s + jitter
    });
  });
}
