import 'dart:math';

class ExponentialBackoff {
  static const int _baseDelaySeconds = 5;
  static const int _maxDelaySeconds = 120;
  static const double _jitterFactor = 0.20; // ±20% jitter

  static Duration calculateDelay(int attempt) {
    if (attempt <= 0) {
      return const Duration(seconds: _baseDelaySeconds);
    }

    final exponential = _baseDelaySeconds * pow(2, attempt - 1).toDouble();
    final clamped = min(exponential, _maxDelaySeconds.toDouble());

    // Jitter aleatorio para evitar thundering herd problem
    final random = Random();
    final jitterRange = clamped * _jitterFactor;
    final jitter = (random.nextDouble() * 2 * jitterRange) - jitterRange;

    final finalSeconds = max(1.0, clamped + jitter);
    return Duration(milliseconds: (finalSeconds * 1000).toInt());
  }
}
