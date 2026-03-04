import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:present_app/config/constants.dart';
import 'package:present_app/models/session_model.dart';
import 'package:present_app/models/course_model.dart';

/// Manages attendance sessions — create, start, end, and listen.
class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create and start a new attendance session for a course.
  Future<SessionModel> startSession({
    required CourseModel course,
    required String lecturerId,
  }) async {
    final doc = _db.collection(AppConstants.sessionsCollection).doc();

    final session = SessionModel(
      id: doc.id,
      courseId: course.id,
      courseName: course.name,
      courseCode: course.code,
      lecturerId: lecturerId,
      roomId: course.roomId,
      roomName: course.roomName,
      status: AppConstants.sessionActive,
      startTime: DateTime.now(),
      attendeeCount: 0,
    );

    await doc.set(session.toFirestore());
    debugPrint('[Session] ✅ Started session for ${course.code}');
    return session;
  }

  /// End an active session.
  Future<void> endSession(String sessionId) async {
    await _db
        .collection(AppConstants.sessionsCollection)
        .doc(sessionId)
        .update({
          'status': AppConstants.sessionClosed,
          'endTime': Timestamp.fromDate(DateTime.now()),
        });
    debugPrint('[Session] ⏹ Ended session $sessionId');
  }

  /// Get active sessions for a student (sessions from their enrolled courses).
  Stream<List<SessionModel>> getActiveSessionsForStudent(
    List<String> courseIds,
  ) {
    if (courseIds.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection(AppConstants.sessionsCollection)
        .where('status', isEqualTo: AppConstants.sessionActive)
        .where('courseId', whereIn: courseIds)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SessionModel.fromFirestore(d)).toList(),
        );
  }

  /// Get active sessions created by a lecturer.
  Stream<List<SessionModel>> getActiveSessionsForLecturer(String lecturerId) {
    return _db
        .collection(AppConstants.sessionsCollection)
        .where('lecturerId', isEqualTo: lecturerId)
        .where('status', isEqualTo: AppConstants.sessionActive)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SessionModel.fromFirestore(d)).toList(),
        );
  }

  /// Get all sessions for a lecturer (active + closed), ordered by time.
  Stream<List<SessionModel>> getAllSessionsForLecturer(String lecturerId) {
    return _db
        .collection(AppConstants.sessionsCollection)
        .where('lecturerId', isEqualTo: lecturerId)
        // Removed .orderBy('startTime') to avoid requiring a Firestore Composite Index
        .limit(20)
        .snapshots()
        .map((snap) {
          final sessions = snap.docs
              .map((d) => SessionModel.fromFirestore(d))
              .toList();
          sessions.sort(
            (a, b) => b.startTime.compareTo(a.startTime),
          ); // descending
          return sessions;
        });
  }

  /// Get courses for a lecturer.
  Future<List<CourseModel>> getCoursesForLecturer(String lecturerId) async {
    final snap = await _db
        .collection(AppConstants.coursesCollection)
        .where('lecturerId', isEqualTo: lecturerId)
        .get();
    return snap.docs.map((d) => CourseModel.fromFirestore(d)).toList();
  }

  /// Get courses for a student.
  Future<List<CourseModel>> getCoursesForStudent(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];

    final snap = await _db
        .collection(AppConstants.coursesCollection)
        .where(FieldPath.documentId, whereIn: courseIds)
        .get();
    return snap.docs.map((d) => CourseModel.fromFirestore(d)).toList();
  }

  /// Increment the attendee count on a session.
  Future<void> incrementAttendeeCount(String sessionId) async {
    await _db.collection(AppConstants.sessionsCollection).doc(sessionId).update(
      {'attendeeCount': FieldValue.increment(1)},
    );
  }

  /// Get all public active sessions (visible to ALL students).
  Stream<List<SessionModel>> getPublicActiveSessions() {
    return _db
        .collection(AppConstants.sessionsCollection)
        .where('status', isEqualTo: AppConstants.sessionActive)
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SessionModel.fromFirestore(d)).toList(),
        );
  }

  /// Create a public session (e.g., "SES Hackathon") that any student can join.
  Future<SessionModel> startPublicSession({
    required String sessionName,
    required String sessionCode,
    required String roomName,
    required String lecturerId,
  }) async {
    final doc = _db.collection(AppConstants.sessionsCollection).doc();

    final session = SessionModel(
      id: doc.id,
      courseId: 'public',
      courseName: sessionName,
      courseCode: sessionCode,
      lecturerId: lecturerId,
      roomId: 'public-room',
      roomName: roomName,
      status: AppConstants.sessionActive,
      startTime: DateTime.now(),
      attendeeCount: 0,
      isPublic: true,
    );

    await doc.set(session.toFirestore());
    debugPrint('[Session] 🌍 Started PUBLIC session: $sessionName');
    return session;
  }
}
