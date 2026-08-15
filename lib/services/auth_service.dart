import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Listen for login/logout changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Currently logged-in user
  User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Unable to create user account.',
      );
    }

    // Save name in Firebase Authentication
    await firebaseUser.updateDisplayName(name);

    final now = DateTime.now();

    // Create our Firestore user model
    final userModel = UserModel(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      createdAt: now,
      updatedAt: now,
    );

    // Save user to Firestore
    await _firestoreService.createUser(userModel);

    return userModel;
  }

  // ─────────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────────

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      return null;
    }

    // Get user's profile from Firestore
    return await _firestoreService.getUser(
      credential.user!.uid,
    );
  }

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }
}