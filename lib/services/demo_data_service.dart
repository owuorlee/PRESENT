import 'package:flutter/material.dart';

/// Seeding service to populate Firestore with demo data.
/// Used for hackathon demonstrations.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:present_app/config/constants.dart';

class DemoDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seed demo courses and rooms. Call once during setup.
  static Future<void> seedDemoData(String lecturerId) async {
    // Create demo rooms
    final rooms = [
      {
        'name': 'LT1 - Main Lecture Hall',
        'building': 'Engineering Block',
        'capacity': 200,
        'latitude': -1.0921,
        'longitude': 37.0115,
        'wifiFingerprint': {
          'AA:BB:CC:DD:EE:01': -45,
          'AA:BB:CC:DD:EE:02': -52,
          'AA:BB:CC:DD:EE:03': -68,
        },
      },
      {
        'name': 'SR3 - Seminar Room',
        'building': 'Science Complex',
        'capacity': 50,
        'latitude': -1.0925,
        'longitude': 37.0120,
        'wifiFingerprint': {'FF:EE:DD:CC:BB:01': -40, 'FF:EE:DD:CC:BB:02': -55},
      },
      {
        'name': 'Lab 204 - Computer Lab',
        'building': 'IT Block',
        'capacity': 80,
        'latitude': -1.0918,
        'longitude': 37.0112,
        'wifiFingerprint': {
          '11:22:33:44:55:01': -38,
          '11:22:33:44:55:02': -42,
          '11:22:33:44:55:03': -60,
        },
      },
    ];

    // Write rooms
    final roomIds = <String>[];
    for (final room in rooms) {
      final doc = _db.collection(AppConstants.roomsCollection).doc();
      await doc.set(room);
      roomIds.add(doc.id);
    }

    // Create demo courses
    final courses = [
      {
        'name': 'Data Structures & Algorithms',
        'code': 'ICS 2204',
        'lecturerId': lecturerId,
        'lecturerName': 'Dr. Kimani',
        'roomId': roomIds[0],
        'roomName': rooms[0]['name'],
        'department': 'Computer Science',
        'enrolledStudentIds': <String>[],
        'schedule': 'Mon 08:00 - 10:00',
      },
      {
        'name': 'Software Engineering',
        'code': 'ICS 2205',
        'lecturerId': lecturerId,
        'lecturerName': 'Dr. Kimani',
        'roomId': roomIds[1],
        'roomName': rooms[1]['name'],
        'department': 'Computer Science',
        'enrolledStudentIds': <String>[],
        'schedule': 'Tue 10:00 - 12:00',
      },
      {
        'name': 'Database Systems',
        'code': 'ICS 2206',
        'lecturerId': lecturerId,
        'lecturerName': 'Dr. Kimani',
        'roomId': roomIds[2],
        'roomName': rooms[2]['name'],
        'department': 'Computer Science',
        'enrolledStudentIds': <String>[],
        'schedule': 'Wed 14:00 - 16:00',
      },
    ];

    for (final course in courses) {
      await _db.collection(AppConstants.coursesCollection).doc().set(course);
    }

    debugPrint(
      '[DemoData] ✅ Seeded ${rooms.length} rooms and ${courses.length} courses',
    );
  }

  /// Enroll a student in all demo courses.
  static Future<void> enrollStudentInAllCourses(String studentId) async {
    final courses = await _db.collection(AppConstants.coursesCollection).get();
    for (final doc in courses.docs) {
      await doc.reference.update({
        'enrolledStudentIds': FieldValue.arrayUnion([studentId]),
      });
    }

    // Also update the user's enrolled course IDs
    await _db.collection(AppConstants.usersCollection).doc(studentId).update({
      'enrolledCourseIds': courses.docs.map((d) => d.id).toList(),
    });

    debugPrint(
      '[DemoData] ✅ Enrolled student in ${courses.docs.length} courses',
    );
  }
}
