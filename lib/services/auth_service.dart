import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:present_app/config/constants.dart';
import 'package:present_app/models/user_model.dart';
import 'package:present_app/services/device_binding_service.dart';

/// Handles authentication and user profile management.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _auth.currentUser != null && _currentUser != null;
  bool get isStudent => _currentUser?.isStudent ?? false;
  bool get isLecturer => _currentUser?.isLecturer ?? false;

  /// Listen to auth state changes.
  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('[Auth] Error loading profile: $e');
    }
  }

  /// Register a new user and bind their device.
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? studentId,
    String? department,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Generate device hash for binding
      final deviceHash = await DeviceBindingService.generateDeviceHash();

      // Create user profile in Firestore
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        studentId: studentId,
        department: department,
        deviceHash: deviceHash,
        deviceRegisteredAt: DateTime.now(),
      );

      await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toFirestore());

      _currentUser = user;
      debugPrint('[Auth] ✅ Registered: $name ($role) — device bound');
      return null; // success
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Registration failed: ${e.message}');
      return e.message ?? 'Registration failed';
    } catch (e) {
      debugPrint('[Auth] Registration error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in an existing user.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserProfile(credential.user!.uid);
      debugPrint('[Auth] ✅ Signed in: ${_currentUser?.name}');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Sign-in failed: ${e.message}');
      return e.message ?? 'Sign-in failed';
    } catch (e) {
      debugPrint('[Auth] Sign-in error: $e');
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
