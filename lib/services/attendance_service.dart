import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:present_app/config/constants.dart';
import 'package:present_app/models/attendance_record_model.dart';
import 'package:present_app/models/room_model.dart';
import 'package:present_app/models/session_model.dart';
import 'package:present_app/models/user_model.dart';
import 'package:present_app/services/biometric_service.dart';
import 'package:present_app/services/device_binding_service.dart';
import 'package:present_app/services/location_service.dart';
import 'package:present_app/services/session_service.dart';

/// The master orchestrator — runs all 3 verification factors and records attendance.
class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService();

  /// Execute the full 3-factor verification and record attendance.
  /// Returns a [VerificationResult] with step-by-step status.
  Future<VerificationResult> markAttendance({
    required UserModel student,
    required SessionModel session,
    bool demoMode = false,
  }) async {
    final result = VerificationResult();

    try {
      // ========== FACTOR 1: Device Binding ==========
      result.currentStep = 'Verifying device...';
      debugPrint('[Attendance] Factor 1: Device binding check');

      if (student.deviceHash == null) {
        result.deviceError = 'No registered device found';
        return result;
      }

      if (demoMode) {
        result.deviceVerified = true;
        debugPrint('[Attendance] 🎭 Demo mode — device verified');
      } else {
        result.deviceVerified = await DeviceBindingService.verifyDevice(
          student.deviceHash!,
        );

        if (!result.deviceVerified) {
          result.deviceError = 'This is not your registered device';
          return result;
        }
      }

      // ========== FACTOR 2: Biometric Verification ==========
      result.currentStep = 'Waiting for biometric...';
      debugPrint('[Attendance] Factor 2: Biometric check');

      result.biometricVerified = await BiometricService.authenticate();

      if (!result.biometricVerified) {
        result.biometricError = 'Biometric verification failed or cancelled';
        return result;
      }

      // ========== FACTOR 3: Location Verification ==========
      result.currentStep = 'Verifying location...';
      debugPrint('[Attendance] Factor 3: Location check');

      // Get room data for GPS + WiFi reference
      final roomDoc = await _db
          .collection(AppConstants.roomsCollection)
          .doc(session.roomId)
          .get();

      if (!roomDoc.exists) {
        // If no room data, use demo mode
        result.locationVerified = demoMode;
        result.wifiScore = demoMode ? 0.85 : 0.0;
        if (!demoMode) {
          result.locationError = 'Room data not found';
          return result;
        }
      } else {
        final room = RoomModel.fromFirestore(roomDoc);
        final locationResult = await LocationService.verifyLocation(
          roomLat: room.latitude,
          roomLng: room.longitude,
          roomWifiFingerprint: room.wifiFingerprint,
          demoMode: demoMode,
        );

        result.locationVerified = locationResult.overallVerified;
        result.wifiScore = locationResult.wifiScore;

        if (!result.locationVerified) {
          result.locationError =
              'You don\'t appear to be in ${session.roomName}';
          return result;
        }
      }

      // ========== ALL FACTORS PASSED — RECORD ATTENDANCE ==========
      result.currentStep = 'Recording attendance...';
      debugPrint('[Attendance] ✅ All 3 factors passed — recording');

      // Check for duplicate
      final existing = await _db
          .collection(AppConstants.attendanceCollection)
          .where('studentId', isEqualTo: student.uid)
          .where('sessionId', isEqualTo: session.id)
          .get();

      if (existing.docs.isNotEmpty) {
        result.alreadyRecorded = true;
        result.currentStep = 'Already recorded';
        return result;
      }

      // Create the attendance record
      final recordDoc = _db.collection(AppConstants.attendanceCollection).doc();

      final record = AttendanceRecord(
        id: recordDoc.id,
        studentId: student.uid,
        studentName: student.name,
        sessionId: session.id,
        courseId: session.courseId,
        roomId: session.roomId,
        timestamp: DateTime.now(),
        deviceVerified: result.deviceVerified,
        biometricVerified: result.biometricVerified,
        locationVerified: result.locationVerified,
        wifiMatchScore: result.wifiScore,
        status: 'verified',
      );

      await recordDoc.set(record.toFirestore());

      // Increment session attendee count
      await _sessionService.incrementAttendeeCount(session.id);

      result.success = true;
      result.currentStep = 'Present! ✅';
      debugPrint('[Attendance] ✅ Attendance recorded for ${student.name}');

      return result;
    } catch (e) {
      debugPrint('[Attendance] Error: $e');
      result.currentStep = 'Error occurred';
      result.generalError = e.toString();
      return result;
    }
  }

  Stream<List<AttendanceRecord>> getSessionAttendance(String sessionId) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('sessionId', isEqualTo: sessionId)
        // Removed .orderBy('timestamp') to avoid requiring a Firestore Composite Index
        .snapshots()
        .map((snap) {
          final records = snap.docs
              .map((d) => AttendanceRecord.fromFirestore(d))
              .toList();
          // Sort client-side
          records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return records;
        });
  }

  /// Get attendance records for a student.
  Future<List<AttendanceRecord>> getStudentAttendance(String studentId) async {
    final snap = await _db
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        // Removed .orderBy('timestamp') to avoid requiring a Firestore Composite Index
        .limit(50)
        .get();
    final records = snap.docs
        .map((d) => AttendanceRecord.fromFirestore(d))
        .toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // descending
    return records;
  }
}

/// Holds the result of the 3-factor verification process.
class VerificationResult {
  String currentStep = '';
  bool deviceVerified = false;
  bool biometricVerified = false;
  bool locationVerified = false;
  double wifiScore = 0.0;
  bool success = false;
  bool alreadyRecorded = false;

  String? deviceError;
  String? biometricError;
  String? locationError;
  String? generalError;

  String? get firstError =>
      deviceError ?? biometricError ?? locationError ?? generalError;
}
