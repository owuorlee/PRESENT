import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric verification (Factor 2).
/// Uses the phone's native biometric system — fingerprint/face/iris.
/// On desktop environments (Windows/macOS), simulates verification for demos.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric authentication is available on this device.
  static Future<bool> isAvailable() async {
    if (kIsWeb) {
      return true; // Simulate availability on web
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true; // Simulate availability on desktop
    }

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('[Biometric] Availability check failed: $e');
      return false;
    }
  }

  /// Get the list of available biometric types.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[Biometric] Failed to get biometrics: $e');
      return [];
    }
  }

  /// Authenticate the user using biometrics.
  /// Returns true if the user successfully authenticated, false otherwise.
  static Future<bool> authenticate() async {
    if (kIsWeb) {
      debugPrint('[Biometric] 🌐 Web mode — Simulating biometric prompt');
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Simulate biometric prompt delay for desktop demos
      debugPrint('[Biometric] 💻 Desktop mode — Simulating biometric prompt');
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Verify your identity to mark attendance',
      );

      if (didAuthenticate) {
        debugPrint('[Biometric] ✅ Authentication successful');
      } else {
        debugPrint('[Biometric] ❌ Authentication failed or cancelled');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[Biometric] Authentication error: $e');
      return false;
    }
  }
}
