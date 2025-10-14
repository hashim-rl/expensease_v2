import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

// --- THIS IS THE NEW, CENTRAL AUTHENTICATION SERVICE ---
// This service acts as the single source of truth for the user's login state.
// It initializes at startup and provides a stable, reactive stream of the
// current user, which eliminates all race conditions.

class AuthService extends GetxService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _authSubscription;

  // Reactive variables that the UI can listen to.
  final Rx<User?> user = Rx<User?>(null);
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // When the service is initialized, start listening to auth state changes.
    _authSubscription = _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  @override
  void onClose() {
    // Clean up the listener when the app is closed.
    _authSubscription.cancel();
    super.onClose();
  }

  /// Initializes the service and waits for the first auth signal.
  Future<AuthService> init() async {
    // This completes once the first user object (or null) is received.
    await _firebaseAuth.authStateChanges().first;
    return this;
  }

  /// Private callback that is triggered whenever the user signs in or out.
  void _onAuthStateChanged(User? firebaseUser) {
    user.value = firebaseUser;
    // Once we have the first signal (either a user or null), we are no longer loading.
    if (isLoading.value) {
      isLoading.value = false;
    }
  }

  /// Helper method to get the current user's ID.
  String? get currentUserId => user.value?.uid;
}