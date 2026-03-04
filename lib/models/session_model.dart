import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String lecturerId;
  final String roomId;
  final String roomName;
  final String status; // 'active' or 'closed'
  final DateTime startTime;
  final DateTime? endTime;
  final int attendeeCount;
  final bool isPublic; // Public sessions are visible to ALL students

  SessionModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.lecturerId,
    required this.roomId,
    required this.roomName,
    required this.status,
    required this.startTime,
    this.endTime,
    this.attendeeCount = 0,
    this.isPublic = false,
  });

  bool get isActive => status == 'active';

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      courseCode: data['courseCode'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      status: data['status'] ?? 'closed',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      attendeeCount: data['attendeeCount'] ?? 0,
      isPublic: data['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'lecturerId': lecturerId,
      'roomId': roomId,
      'roomName': roomName,
      'status': status,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'attendeeCount': attendeeCount,
      'isPublic': isPublic,
    };
  }
}
