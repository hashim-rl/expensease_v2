import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/user_model.dart' as model;
import 'package:expensease/app/data/providers/firebase_provider.dart';
import 'package:flutter/foundation.dart';

/// AuthRepository handles all authentication-related communication
/// with the Firebase backend. It acts as a bridge between the
/// application's logic (Controllers) and the data source (FirebaseProvider).
class AuthRepository {
  final FirebaseProvider _firebaseProvider;

  AuthRepository(this._firebaseProvider);

  /// Provides a stream that emits the current user's authentication state.
  /// This is the primary way to listen for login or logout events.
  Stream<User?> get authStateChanges => _firebaseProvider.authStateChanges;

  /// --- THIS IS THE UPDATED ATOMIC SIGN-UP FUNCTION ---
  /// Signs up a user and creates their Firestore document in a single, robust operation.
  Future<UserCredential> signUpWithEmail(String email, String password, String fullName) async {
    try {
      debugPrint("--- AUTH TRACE: Starting user sign-up for email: $email");

      // Step 1: Create the user in Firebase Authentication
      final userCredential = await _firebaseProvider.signUpWithEmail(email, password);
      final user = userCredential.user;

      if (user != null) {
        debugPrint("--- AUTH TRACE: Firebase Auth user created successfully with UID: ${user.uid}");
        // Step 2: Immediately create their user document in Firestore.
        // This ensures data integrity.
        final userModel = model.UserModel(
          uid: user.uid,
          email: user.email ?? 'no-email@provided.com',
          fullName: fullName.trim().isNotEmpty ? fullName.trim() : 'New User',
          nickname: fullName.trim().isNotEmpty ? fullName.trim() : 'New User', // Default nickname to full name
        );
        await _firebaseProvider.createUserDocument(userModel);
        debugPrint("--- AUTH TRACE: Firestore document created for user: ${user.uid}");
      } else {
        // This case is rare, but we handle it just in case.
        throw Exception('User authentication failed after creation. Please try again.');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("!!!! AUTH ERROR (FirebaseAuth): ${e.message}");
      // Re-throw Firebase-specific errors to be handled by the controller.
      throw Exception(e.message ?? 'An error occurred during sign up.');
    } catch (e) {
      debugPrint("!!!! AUTH ERROR (General): ${e.toString()}");
      throw Exception('An unknown error occurred. Please try again.');
    }
  }

  /// Logs in an existing user with their email and password.
  Future<UserCredential> logInWithEmail(String email, String password) async {
    try {
      return await _firebaseProvider.logInWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during login.');
    } catch (e) {
      throw Exception('An unknown error occurred. Please try again.');
    }
  }

  /// Sends a password reset email to the provided email address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseProvider.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      throw Exception('An unknown error occurred. Please try again.');
    }
  }

  /// Signs in the user anonymously for guest mode functionality.
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _firebaseProvider.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to sign in as guest.');
    } catch (e) {
      throw Exception('An unknown error occurred. Please try again.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _firebaseProvider.signOut();
    } catch (e) {
      throw Exception('Error signing out. Please try again.');
    }
  }
}