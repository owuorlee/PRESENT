import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:present_app/config/theme.dart';
import 'package:present_app/models/session_model.dart';
import 'package:present_app/services/auth_service.dart';
import 'package:present_app/services/session_service.dart';
import 'package:present_app/services/demo_data_service.dart';
import 'package:present_app/screens/student/check_in_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final SessionService _sessionService = SessionService();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser!;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hey, ${user.name.split(' ').first} 👋',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.studentId ?? 'Student',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Demo enroll button
                    IconButton(
                      onPressed: () async {
                        await DemoDataService.enrollStudentInAllCourses(
                          user.uid,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Enrolled in all demo courses'),
                              backgroundColor: AppTheme.accent,
                            ),
                          );
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.playlist_add),
                      tooltip: 'Enroll in demo courses',
                    ),
                    IconButton(
                      onPressed: () => auth.signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Sign out',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.15),
                        AppTheme.primaryLight.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.phonelink_lock,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Device Bound ✅',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '3-factor verification active',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _factorChip('🔗'),
                      const SizedBox(width: 6),
                      _factorChip('👆'),
                      const SizedBox(width: 6),
                      _factorChip('📍'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Active Sessions header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE SESSIONS',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sessions list — shows both enrolled AND public sessions
              Expanded(
                child: StreamBuilder<List<SessionModel>>(
                  stream: _sessionService.getPublicActiveSessions(),
                  builder: (context, publicSnap) {
                    return StreamBuilder<List<SessionModel>>(
                      stream: user.enrolledCourseIds.isNotEmpty
                          ? _sessionService.getActiveSessionsForStudent(
                              user.enrolledCourseIds,
                            )
                          : Stream.value([]),
                      builder: (context, enrolledSnap) {
                        if (publicSnap.connectionState ==
                                ConnectionState.waiting &&
                            enrolledSnap.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                            ),
                          );
                        }

                        // Merge both lists, removing duplicates by session ID
                        final Map<String, SessionModel> sessionMap = {};
                        for (final s in (publicSnap.data ?? [])) {
                          sessionMap[s.id] = s;
                        }
                        for (final s in (enrolledSnap.data ?? [])) {
                          sessionMap[s.id] = s;
                        }
                        final sessions = sessionMap.values.toList();

                        if (sessions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 64,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No active sessions right now',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sessions appear when a lecturer starts one',
                                  style: TextStyle(
                                    color: AppTheme.textMuted.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) =>
                              _sessionCard(context, sessions[index]),
                        );
                      },
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

  Widget _factorChip(String emoji) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.dark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }

  Widget _sessionCard(BuildContext context, SessionModel session) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CheckInScreen(session: session)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.2),
                    AppTheme.primaryLight.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.courseCode,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.courseName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${session.roomName}',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'CHECK IN',
                style: TextStyle(
                  color: AppTheme.dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
