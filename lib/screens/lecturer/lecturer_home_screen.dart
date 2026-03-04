import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:present_app/config/theme.dart';
import 'package:present_app/models/course_model.dart';
import 'package:present_app/models/session_model.dart';
import 'package:present_app/services/auth_service.dart';
import 'package:present_app/services/session_service.dart';
import 'package:present_app/services/demo_data_service.dart';
import 'package:present_app/screens/lecturer/session_screen.dart';

class LecturerHomeScreen extends StatefulWidget {
  const LecturerHomeScreen({super.key});

  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  final SessionService _sessionService = SessionService();
  List<CourseModel> _courses = [];
  bool _loadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final courses = await _sessionService.getCoursesForLecturer(
      auth.currentUser!.uid,
    );
    if (mounted) {
      setState(() {
        _courses = courses;
        _loadingCourses = false;
      });
    }
  }

  Future<void> _seedData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await DemoDataService.seedDemoData(auth.currentUser!.uid);
    await _loadCourses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demo data seeded — 3 courses & 3 rooms'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  Future<void> _startSession(CourseModel course) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final session = await _sessionService.startSession(
      course: course,
      lecturerId: auth.currentUser!.uid,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SessionScreen(session: session)),
      );
    }
  }

  Future<void> _startHackathonSession() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final session = await _sessionService.startPublicSession(
      sessionName: 'SES Hackathon 2026',
      sessionCode: 'SES WED',
      roomName: 'IPIC - JKUAT',
      lecturerId: auth.currentUser!.uid,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SessionScreen(session: session)),
      );
    }
  }

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
                            'Welcome, ${user.name.split(' ').first}',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lecturer Dashboard',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _seedData,
                      icon: const Icon(Icons.dataset_outlined),
                      tooltip: 'Seed demo data',
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

              // 🎯 SES Hackathon — Public Session Launch Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _startHackathonSession,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.2),
                          AppTheme.orange.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.rocket_launch,
                            color: AppTheme.accent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚀 SES HACKATHON 2026',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Start public session — all students can join',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Active sessions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'ACTIVE SESSIONS',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 100,
                child: StreamBuilder<List<SessionModel>>(
                  stream: _sessionService.getActiveSessionsForLecturer(
                    user.uid,
                  ),
                  builder: (context, snapshot) {
                    final activeSessions = snapshot.data ?? [];
                    if (activeSessions.isEmpty) {
                      return Center(
                        child: Text(
                          'No active sessions',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: activeSessions.length,
                      itemBuilder: (ctx, i) =>
                          _activeSessionChip(activeSessions[i]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Courses
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'MY COURSES',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _loadingCourses
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      )
                    : _courses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courses found',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _seedData,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Seed Demo Courses'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _courses.length,
                        itemBuilder: (ctx, i) => _courseCard(_courses[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeSessionChip(SessionModel session) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SessionScreen(session: session)),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
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
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.courseCode,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              '${session.attendeeCount} students',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.code,
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '📍 ${course.roomName} • ${course.schedule}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _startSession(course),
            child: const Text('START'),
          ),
        ],
      ),
    );
  }
}
