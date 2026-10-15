import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Manages user profile state independently of AuthProvider.
/// Listens to FirebaseAuth directly so it auto-loads when user logs in
/// and clears when user logs out — no manual wiring needed.
class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<User?>? _authSub;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    _listenToAuth();
  }

  // ── Auto-sync with Firebase Auth ──────────────────────────────────────
  void _listenToAuth() {
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
          if (fbUser != null) {
            _isLoading = true;
            notifyListeners();
            try {
              _user = await _firestoreService.getUser(fbUser.uid);
            } catch (_) {
              _user = null;
            }
            _isLoading = false;
            notifyListeners();
          } else {
            _user = null;
            _isLoading = false;
            notifyListeners();
          }
        });
  }

  // ── Manual set (called by AuthProvider after signup/profile update) ───
  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  // ── Update profile in Firestore + local state ─────────────────────────
  Future<bool> updateProfile(UserModel updated) async {
    try {
      await _firestoreService.updateUser(updated);
      _user = updated;
      _error = null;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to save profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── Reload from Firestore ─────────────────────────────────────────────
  Future<void> refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      _user = await _firestoreService.getUser(uid);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
