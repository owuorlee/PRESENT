class AppConstants {
  static const String appName = 'Present';
  static const String appTagline = 'Smart Attendance & Campus Intelligence';

  // Geofence radius in meters
  static const double geofenceRadius = 150.0;

  // WiFi fingerprint match threshold (0.0 - 1.0)
  static const double wifiMatchThreshold = 0.6;

  // Session window duration in minutes
  static const int defaultSessionWindowMinutes = 15;

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String coursesCollection = 'courses';
  static const String roomsCollection = 'rooms';
  static const String sessionsCollection = 'sessions';
  static const String attendanceCollection = 'attendance_records';

  // User roles
  static const String roleStudent = 'student';
  static const String roleLecturer = 'lecturer';

  // Session statuses
  static const String sessionActive = 'active';
  static const String sessionClosed = 'closed';
}
