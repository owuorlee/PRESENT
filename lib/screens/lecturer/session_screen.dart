import 'package:flutter/material.dart';
import 'package:present_app/config/theme.dart';
import 'package:present_app/models/attendance_record_model.dart';
import 'package:present_app/models/session_model.dart';
import 'package:present_app/services/attendance_service.dart';
import 'package:present_app/services/session_service.dart';
import 'package:intl/intl.dart';

class SessionScreen extends StatefulWidget {
  final SessionModel session;
  const SessionScreen({super.key, required this.session});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final SessionService _sessionService = SessionService();
  bool _isActive = true;

  Future<void> _endSession() async {
    await _sessionService.endSession(widget.session.id);
    setState(() => _isActive = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkPurple, AppTheme.dark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.session.courseCode,
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: AppTheme.accent,
                                        size: 6,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            widget.session.courseName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isActive)
                      OutlinedButton(
                        onPressed: _endSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.red,
                          side: const BorderSide(color: AppTheme.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'END SESSION',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Room info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.session.roomName,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(widget.session.startTime),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Attendance list header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'STUDENTS CHECKED IN',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    StreamBuilder<List<AttendanceRecord>>(
                      stream: _attendanceService.getSessionAttendance(
                        widget.session.id,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count present',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Real-time attendance feed
              Expanded(
                child: StreamBuilder<List<AttendanceRecord>>(
                  stream: _attendanceService.getSessionAttendance(
                    widget.session.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      );
                    }

                    final records = snapshot.data ?? [];

                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isActive
                                  ? 'Waiting for students to check in...'
                                  : 'No students checked in',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: records.length,
                      itemBuilder: (ctx, i) =>
                          _attendanceTile(records[i], i + 1),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceTile(AttendanceRecord record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Index
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm:ss').format(record.timestamp),
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Verification factors
          _miniFactorIcon('🔗', record.deviceVerified),
          const SizedBox(width: 4),
          _miniFactorIcon('👆', record.biometricVerified),
          const SizedBox(width: 4),
          _miniFactorIcon('📍', record.locationVerified),
          const SizedBox(width: 8),
          // Status
          const Icon(Icons.verified_rounded, color: AppTheme.accent, size: 22),
        ],
      ),
    );
  }

  Widget _miniFactorIcon(String emoji, bool verified) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: verified
            ? AppTheme.accent.withValues(alpha: 0.15)
            : AppTheme.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 12))),
    );
  }
}
