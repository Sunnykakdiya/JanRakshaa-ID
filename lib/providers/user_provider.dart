import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Mirrors the signed-in user's Firestore profile in real time.
///
/// Kept separate from AuthProvider (which only fetches the profile once,
/// on sign-in) so that profile edits — from this device or any other —
/// show up instantly across the app without touching the auth flow.
/// It listens to Firebase's own auth stream directly, the same way
/// AuthProvider does, so it stays in sync without needing to be wired
/// through a ProxyProvider.
class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  void _onAuthChanged(User? firebaseUser) {
    _userSub?.cancel();

    if (firebaseUser == null) {
      _user = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _userSub = _firestoreService.userStream(firebaseUser.uid).listen(
          (userModel) {
        _user = userModel;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Failed to load profile.';
        notifyListeners();
      },
    );
  }

  /// Saves profile edits to Firestore. Returns true on success.
  Future<bool> updateProfile(UserModel updated) async {
    _errorMessage = null;
    try {
      await _firestoreService.updateUser(updated);
      _user = updated;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Could not save changes. Please try again.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
