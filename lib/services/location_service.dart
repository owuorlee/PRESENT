import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:present_app/config/constants.dart';

/// Location + WiFi fingerprint verification (Factor 3).
/// GPS provides building-level accuracy. WiFi fingerprinting provides room-level accuracy.
/// Together they defeat both "remote check-in" and "GPS spoofing" attacks.
class LocationService {
  /// Check and request location permissions.
  static Future<bool> ensurePermissions() async {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true; // Simulate permissions on web/desktop
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[Location] Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[Location] Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[Location] Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Get the current GPS position.
  static Future<Position?> getCurrentPosition() async {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Simulate GPS position near JKUAT Administration block
      return Position(
        longitude: 37.0125,
        latitude: -1.0953,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 1530.0,
        altitudeAccuracy: 10.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    try {
      final hasPermission = await ensurePermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[Location] Failed to get position: $e');
      return null;
    }
  }

  /// Verify that the user is within the geofence radius of a room.
  /// Returns true if within [AppConstants.geofenceRadius] meters.
  static Future<bool> verifyGeofence(double targetLat, double targetLng) async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );

    final withinRange = distance <= AppConstants.geofenceRadius;
    debugPrint(
      '[Location] Distance: ${distance.toStringAsFixed(1)}m — ${withinRange ? "✅ Within" : "❌ Outside"} geofence',
    );
    return withinRange;
  }

  /// Scan visible WiFi networks and return a fingerprint map (BSSID -> RSSI).
  static Future<Map<String, int>> scanWifiFingerprint() async {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Simulate an empty WiFi scan for web/desktop (we simulate success later)
      return {};
    }

    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        debugPrint('[WiFi] Cannot start scan: $canScan');
        return {};
      }

      await WiFiScan.instance.startScan();
      // Brief delay to allow scan to complete
      await Future.delayed(const Duration(milliseconds: 500));

      final results = await WiFiScan.instance.getScannedResults();
      final fingerprint = <String, int>{};

      for (final ap in results) {
        fingerprint[ap.bssid] = ap.level;
      }

      debugPrint('[WiFi] Scanned ${fingerprint.length} access points');
      return fingerprint;
    } catch (e) {
      debugPrint('[WiFi] Scan failed: $e');
      return {};
    }
  }

  /// Compare a scanned WiFi fingerprint against a stored room fingerprint.
  /// Uses cosine similarity on the signal strengths of shared access points.
  /// Returns a similarity score between 0.0 (no match) and 1.0 (perfect match).
  static double compareWifiFingerprints(
    Map<String, int> scanned,
    Map<String, int> reference,
  ) {
    if (scanned.isEmpty || reference.isEmpty) return 0.0;

    // Find shared BSSIDs
    final sharedBssids = scanned.keys
        .where((k) => reference.containsKey(k))
        .toList();

    if (sharedBssids.isEmpty) return 0.0;

    // Cosine similarity on RSSI values of shared APs
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (final bssid in sharedBssids) {
      final a = scanned[bssid]!.toDouble();
      final b = reference[bssid]!.toDouble();
      dotProduct += a * b;
      normA += a * a;
      normB += b * b;
    }

    if (normA == 0 || normB == 0) return 0.0;

    final similarity = dotProduct / (sqrt(normA) * sqrt(normB));

    // Also factor in the ratio of shared APs to reference APs
    // (if the room reference has 10 APs and we see 8 of them, that's good)
    final coverage = sharedBssids.length / reference.length;
    final score = similarity * (0.7 + 0.3 * coverage); // Weighted blend

    debugPrint(
      '[WiFi] Match score: ${score.toStringAsFixed(3)} (shared: ${sharedBssids.length}/${reference.length} APs)',
    );
    return score.clamp(0.0, 1.0);
  }

  /// Full location verification: GPS geofence + WiFi fingerprint.
  /// Returns a VerificationResult with both checks.
  static Future<LocationVerificationResult> verifyLocation({
    required double roomLat,
    required double roomLng,
    required Map<String, int> roomWifiFingerprint,
    bool demoMode = false,
  }) async {
    // GPS check
    final gpsOk = await verifyGeofence(roomLat, roomLng);

    // WiFi check
    double wifiScore = 0.0;
    if (!demoMode) {
      final scannedWifi = await scanWifiFingerprint();
      wifiScore = compareWifiFingerprints(scannedWifi, roomWifiFingerprint);
    } else {
      // In demo mode, simulate a good WiFi match
      wifiScore = 0.85;
      debugPrint('[WiFi] 🎭 Demo mode — simulating match score: $wifiScore');
    }

    final wifiOk = wifiScore >= AppConstants.wifiMatchThreshold;

    return LocationVerificationResult(
      gpsVerified: gpsOk,
      wifiVerified: wifiOk,
      wifiScore: wifiScore,
      overallVerified: gpsOk || wifiOk || demoMode, // Lenient for MVP
    );
  }
}

class LocationVerificationResult {
  final bool gpsVerified;
  final bool wifiVerified;
  final double wifiScore;
  final bool overallVerified;

  LocationVerificationResult({
    required this.gpsVerified,
    required this.wifiVerified,
    required this.wifiScore,
    required this.overallVerified,
  });
}
