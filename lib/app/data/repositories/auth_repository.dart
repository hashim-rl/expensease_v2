import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/user_model.dart' as model;
import 'package:expensease/app/data/providers/firebase_provider.dart';

/// AuthRepository handles all authentication-related communication
/// with the Firebase backend. It acts as a bridge between the
/// application's logic (Controllers) and the data source (FirebaseProvider).
class AuthRepository {
  final FirebaseProvider _firebaseProvider;

  AuthRepository(this._firebaseProvider);

  /// Provides a stream that emits the current user's authentication state.
  /// This is the primary way to listen for login or logout events.
  Stream<User?> get authStateChanges => _firebaseProvider.authStateChanges;

  /// Signs up a new user with email/password and creates their user document.
  /// Throws a clear exception if the sign-up fails.
  /// --- THIS IS THE FIX ---
  /// We now require fullName to ensure the document is created.
  Future<UserCredential> signUpWithEmail(String email, String password, String fullName) async {
    try {
      // Step 1: Create the user in Firebase Authentication
      final userCredential = await _firebaseProvider.signUpWithEmail(email, password);
      final user = userCredential.user;

      // Step 2: If the auth user was created, immediately create their document in Firestore
      if (user != null) {
        await createUserDocument(user, fullName);
      } else {
        // This case is rare, but we handle it just in case.
        throw Exception('User was not created. Please try again.');
      }

      return userCredential;

    } on FirebaseAuthException catch (e) {
      // Re-throw Firebase-specific errors to be handled by the controller.
      throw Exception(e.message ?? 'An error occurred during sign up.');
    } catch (e) {
      throw Exception('An unknown error occurred. Please try again.');
    }
  }

  /// Logs in an existing user with their email and password.
  /// Throws a clear exception if the login fails.
  Future<UserCredential> logInWithEmail(String email, String password) async {
    try {
      return await _firebaseProvider.logInWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      // Re-throw Firebase-specific errors.
      throw Exception(e.message ?? 'An error occurred during login.');
    } catch (e) {
      throw Exception('An unknown error occurred. Please try again.');
    }
  }

  /// Creates a user document in the Firestore database after successful sign-up.
  /// This stores additional user information like their full name.
  Future<void> createUserDocument(User user, String fullName) async {
    try {
      final userModel = model.UserModel(
        uid: user.uid,
        email: user.email ?? '',
        fullName: fullName,
      );
      await _firebaseProvider.createUserDocument(userModel);
    } catch (e) {
      // It's important to handle potential errors when writing to the database.
      throw Exception('Failed to save user details. Please try again.');
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
      // While less common, sign-out can also fail.
      throw Exception('Error signing out. Please try again.');
    }
  }
}