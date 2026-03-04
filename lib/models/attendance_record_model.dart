import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String sessionId;
  final String courseId;
  final String roomId;
  final DateTime timestamp;
  final bool deviceVerified;
  final bool biometricVerified;
  final bool locationVerified;
  final double? wifiMatchScore;
  final String status; // 'verified', 'late', 'rejected'

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.sessionId,
    required this.courseId,
    required this.roomId,
    required this.timestamp,
    required this.deviceVerified,
    required this.biometricVerified,
    required this.locationVerified,
    this.wifiMatchScore,
    this.status = 'verified',
  });

  bool get allFactorsVerified =>
      deviceVerified && biometricVerified && locationVerified;

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      sessionId: data['sessionId'] ?? '',
      courseId: data['courseId'] ?? '',
      roomId: data['roomId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceVerified: data['deviceVerified'] ?? false,
      biometricVerified: data['biometricVerified'] ?? false,
      locationVerified: data['locationVerified'] ?? false,
      wifiMatchScore: data['wifiMatchScore']?.toDouble(),
      status: data['status'] ?? 'verified',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'sessionId': sessionId,
      'courseId': courseId,
      'roomId': roomId,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceVerified': deviceVerified,
      'biometricVerified': biometricVerified,
      'locationVerified': locationVerified,
      'wifiMatchScore': wifiMatchScore,
      'status': status,
    };
  }
}
