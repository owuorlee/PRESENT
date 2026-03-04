import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Generates a unique device hash for device binding (Factor 1).
/// The hash is derived from hardware identifiers that are consistent
/// across app reinstalls on the same physical device.
class DeviceBindingService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Generate a SHA-256 hash of the device's hardware identifiers.
  /// This hash serves as the cryptographic link between a student and their phone.
  static Future<String> generateDeviceHash() async {
    String rawIdentifier;

    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      rawIdentifier = [
        webInfo.vendor,
        webInfo.userAgent,
        webInfo.hardwareConcurrency.toString(),
      ].join('|');
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // Combine multiple hardware identifiers for a robust fingerprint
      rawIdentifier = [
        androidInfo.id, // Build ID
        androidInfo.brand, // Device brand
        androidInfo.model, // Device model
        androidInfo.hardware, // Hardware name
        androidInfo.fingerprint, // Build fingerprint (unique per device+ROM)
      ].join('|');
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      rawIdentifier = [
        iosInfo.identifierForVendor ?? 'unknown',
        iosInfo.model,
        iosInfo.systemVersion,
      ].join('|');
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      rawIdentifier = [
        windowsInfo.computerName,
        windowsInfo.productId,
      ].join('|');
    } else {
      rawIdentifier = 'unknown-platform';
    }

    // SHA-256 hash — one-way, can't be reversed to get device info
    final bytes = utf8.encode(rawIdentifier);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify that the current device matches the registered hash.
  static Future<bool> verifyDevice(String registeredHash) async {
    try {
      final currentHash = await generateDeviceHash();
      final matches = currentHash == registeredHash;
      if (!matches) {
        debugPrint(
          '[DeviceBinding] ❌ Hash mismatch — different device detected',
        );
      }
      return matches;
    } catch (e) {
      debugPrint('[DeviceBinding] Error verifying device: $e');
      return false;
    }
  }
}
