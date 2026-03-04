import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student' or 'lecturer'
  final String? studentId;
  final String? department;
  final String? deviceHash;
  final DateTime? deviceRegisteredAt;
  final List<String> enrolledCourseIds;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.department,
    this.deviceHash,
    this.deviceRegisteredAt,
    this.enrolledCourseIds = const [],
  });

  bool get isStudent => role == 'student';
  bool get isLecturer => role == 'lecturer';
  bool get hasRegisteredDevice => deviceHash != null;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      studentId: data['studentId'],
      department: data['department'],
      deviceHash: data['deviceHash'],
      deviceRegisteredAt: data['deviceRegisteredAt'] != null
          ? (data['deviceRegisteredAt'] as Timestamp).toDate()
          : null,
      enrolledCourseIds: List<String>.from(data['enrolledCourseIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'studentId': studentId,
      'department': department,
      'deviceHash': deviceHash,
      'deviceRegisteredAt': deviceRegisteredAt != null
          ? Timestamp.fromDate(deviceRegisteredAt!)
          : null,
      'enrolledCourseIds': enrolledCourseIds,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? studentId,
    String? department,
    String? deviceHash,
    DateTime? deviceRegisteredAt,
    List<String>? enrolledCourseIds,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      deviceHash: deviceHash ?? this.deviceHash,
      deviceRegisteredAt: deviceRegisteredAt ?? this.deviceRegisteredAt,
      enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
    );
  }
}
