import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String code;
  final String lecturerId;
  final String lecturerName;
  final String roomId;
  final String roomName;
  final String department;
  final List<String> enrolledStudentIds;
  final String schedule; // e.g. "Mon 10:00-12:00"

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.lecturerId,
    required this.lecturerName,
    required this.roomId,
    required this.roomName,
    required this.department,
    this.enrolledStudentIds = const [],
    this.schedule = '',
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      department: data['department'] ?? '',
      enrolledStudentIds: List<String>.from(data['enrolledStudentIds'] ?? []),
      schedule: data['schedule'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'roomId': roomId,
      'roomName': roomName,
      'department': department,
      'enrolledStudentIds': enrolledStudentIds,
      'schedule': schedule,
    };
  }
}
