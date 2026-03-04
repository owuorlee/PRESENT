import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:present_app/config/theme.dart';
import 'package:present_app/models/session_model.dart';
import 'package:present_app/services/auth_service.dart';
import 'package:present_app/services/attendance_service.dart';

class CheckInScreen extends StatefulWidget {
  final SessionModel session;
  const CheckInScreen({super.key, required this.session});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isVerifying = false;
  VerificationResult? _result;
  int _currentStep = 0; // 0=ready, 1=device, 2=biometric, 3=location, 4=done
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser!;

    setState(() {
      _isVerifying = true;
      _currentStep = 1;
      _result = null;
    });

    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _currentStep = 2); // Biometric step
    await Future.delayed(const Duration(milliseconds: 200));

    final result = await _attendanceService.markAttendance(
      student: user,
      session: widget.session,
      demoMode: true, // Demo mode for hackathon
    );

    setState(() {
      _result = result;
      _currentStep = result.success ? 4 : 0;
      _isVerifying = false;
    });
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
              // App Bar
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
                          Text(
                            widget.session.courseCode,
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            widget.session.courseName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Verification circle
                        _buildVerificationCircle(),
                        const SizedBox(height: 40),

                        // Status text
                        _buildStatusText(),
                        const SizedBox(height: 40),

                        // Factor indicators
                        _buildFactorIndicators(),
                        const SizedBox(height: 40),

                        // Action button
                        if (!_isVerifying && _currentStep != 4)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _startVerification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _result?.firstError != null
                                    ? AppTheme.orange
                                    : AppTheme.accent,
                              ),
                              child: Text(
                                _result?.firstError != null
                                    ? 'RETRY VERIFICATION'
                                    : 'MARK PRESENT',
                                style: const TextStyle(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                        // Error message
                        if (_result?.firstError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _result!.firstError!,
                                      style: const TextStyle(
                                        color: AppTheme.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_result?.alreadyRecorded == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.accent,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'You\'re already marked present!',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Room info
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            '📍 ${widget.session.roomName}',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCircle() {
    final isSuccess = _currentStep == 4;
    final isError = _result?.firstError != null && !_isVerifying;
    final color = isSuccess
        ? AppTheme.accent
        : isError
        ? AppTheme.red
        : AppTheme.primaryLight;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _isVerifying
            ? 1.0 + (_pulseController.value * 0.08)
            : isSuccess
            ? 1.0
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: _isVerifying ? 40 : 20,
                  spreadRadius: _isVerifying ? 10 : 0,
                ),
              ],
            ),
            child: Center(
              child: _isVerifying
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      isSuccess
                          ? Icons.check_rounded
                          : isError
                          ? Icons.close_rounded
                          : Icons.fingerprint,
                      size: 72,
                      color: color,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    String title;
    String subtitle;

    if (_currentStep == 4) {
      title = 'Present! ✅';
      subtitle = 'Attendance verified and recorded';
    } else if (_isVerifying) {
      title = 'Verifying...';
      subtitle = _result?.currentStep ?? 'Running 3-factor check';
    } else if (_result?.firstError != null) {
      title = 'Verification Failed';
      subtitle = 'One or more factors did not pass';
    } else {
      title = 'Ready to Check In';
      subtitle = '3-factor verification will run automatically';
    }

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: _currentStep == 4 ? AppTheme.accent : AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFactorIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _factorPill(
          '🔗',
          'Device',
          _result?.deviceVerified == true,
          _currentStep >= 1 && _isVerifying,
        ),
        const SizedBox(width: 12),
        _factorPill(
          '👆',
          'Biometric',
          _result?.biometricVerified == true,
          _currentStep >= 2 && _isVerifying,
        ),
        const SizedBox(width: 12),
        _factorPill(
          '📍',
          'Location',
          _result?.locationVerified == true,
          _currentStep >= 3 && _isVerifying,
        ),
      ],
    );
  }

  Widget _factorPill(
    String emoji,
    String label,
    bool verified,
    bool inProgress,
  ) {
    final color = verified
        ? AppTheme.accent
        : inProgress
        ? AppTheme.primaryLight
        : AppTheme.textMuted.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (verified)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check, color: AppTheme.accent, size: 14),
            ),
        ],
      ),
    );
  }
}
