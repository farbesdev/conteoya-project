import 'dart:io';
import 'package:crypto/crypto.dart';

class HashUtils {
  /// Calcula el hash SHA-256 de un archivo local.
  static Future<String> calculateFileSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Calcula el hash SHA-256 de una cadena de texto o JSON.
  static String calculateStringSha256(String input) {
    return sha256.convert(input.codeUnits).toString();
  }
}
