import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _userModel;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated;

  AuthProvider() {
    _listenToAuthChanges();
  }

  // ─────────────────────────────────────────────
  // AUTH STATE
  // ─────────────────────────────────────────────

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _userModel = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      try {
        _userModel =
        await _firestoreService.getUser(user.uid);

        _status = AuthStatus.authenticated;
      } catch (_) {
        _userModel = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Unable to load your profile.';
      }

      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _clearError();

    try {
      _userModel = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage =
      'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _clearError();

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage =
      'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();

    _userModel = null;
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────

  void updateLocalUser(UserModel updated) {
    _userModel = updated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_userModel == null) return;

    try {
      final fresh =
      await _firestoreService.getUser(_userModel!.uid);

      if (fresh != null) {
        _userModel = fresh;
        notifyListeners();
      }
    } catch (_) {
      // Keep existing data if refresh fails.
    }
  }

  Future<bool> updateProfile(UserModel updated) async {
    try {
      await _firestoreService.updateUser(updated);

      _userModel = updated;
      notifyListeners();

      return true;
    } catch (_) {
      _errorMessage = 'Failed to update profile.';
      notifyListeners();

      return false;
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Password must be at least 6 characters.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'No internet connection.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}