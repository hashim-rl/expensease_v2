import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/routes/app_routes.dart';
// --- NEW IMPORTS ---
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
// ---------------------

class AuthController extends GetxController {
  final AuthRepository _repository = Get.find<AuthRepository>();
  // --- NEW INJECTION ---
  final GroupController _groupController = Get.find<GroupController>();
  // ---------------------

  final isLoading = false.obs;
  final GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> logInFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> passwordResetFormKey = GlobalKey<FormState>();

  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController resetEmailController;

  @override
  void onInit() {
    super.onInit();
    fullNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    resetEmailController = TextEditingController();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.onClose();
  }

  // --- THIS IS THE UPDATED SIGN-UP LOGIC ---
  Future<void> signUp() async {
    final isValid = signUpFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    isLoading.value = true;
    try {
      // The repository now handles creating the auth user and their
      // database document in a single, reliable call.
      await _repository.signUpWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
        fullNameController.text.trim(),
      );

      _clearControllers();
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      Get.snackbar('Sign Up Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logIn() async {
    final isValid = logInFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    isLoading.value = true;
    try {
      await _repository.logInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      _clearControllers();
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    // Clear any local group data if we sign out
    _groupController.clearActiveGroup();
    Get.offAllNamed(Routes.AUTH_HUB);
  }

  Future<void> signInAsGuest() async {
    isLoading.value = true;
    try {
      await _repository.signInAnonymously();
      Get.offAllNamed(Routes.GUEST_MODE);
    } catch (e) {
      Get.snackbar('Guest Mode Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // --- NEW METHOD FOR GUEST MODE GROUP CREATION ---
  Future<void> createLocalGuestGroup() async {
    isLoading.value = true;
    try {
      // 1. Create a dummy UserModel for the Guest
      final guestUser = UserModel(
        uid: 'guest_user_id', // Unique placeholder UID for local mode
        fullName: 'Guest User',
        email: 'guest@expensease.local',
        nickname: 'You',
        photoUrl: '',
        currencyCode: 'USD',
        isGuest: true, // Flag to distinguish guest data
      );

      // 2. Create a basic GroupModel
      final guestGroup = GroupModel(
        id: 'local_group_id', // Unique placeholder Group ID
        name: 'My Local Group',
        description: 'Temporary group for trying ExpensEase.',
        ownerUid: guestUser.uid,
        memberUids: [guestUser.uid],
        mode: 'standard',
        createdAt: DateTime.now(),
        // This flag ensures the GroupController knows not to use Firebase
        isLocal: true,
      );

      // 3. Set the active group and user in the GroupController
      // Note: We need to also set the active user context in the UserService/AuthService
      // if it wasn't already handled by the anonymous sign-in in _repository.
      // For now, rely on GroupController to hold the local group state.
      _groupController.setActiveGroup(guestGroup);
      _groupController.setLocalUser(guestUser); // Assuming a new method for local user

      // 4. Navigate to the Group Dashboard
      Get.offAllNamed(Routes.DASHBOARD);
      Get.snackbar('Success', 'Local group created! Start adding expenses.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar('Error', 'Failed to create local group: $e');
    } finally {
      isLoading.value = false;
    }
  }
  // ------------------------------------------------

  Future<void> sendPasswordResetEmail() async {
    final isValid = passwordResetFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    isLoading.value = true;
    try {
      await _repository.sendPasswordResetEmail(resetEmailController.text.trim());
      Get.back();
      Get.snackbar(
        'Check Your Email',
        'A password reset link has been sent.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      resetEmailController.clear();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _clearControllers() {
    fullNameController.clear();
    emailController.clear();
    passwordController.clear();
  }

  void goToLoginPage() => Get.toNamed(Routes.LOGIN);
  void goToSignupPage() => Get.toNamed(Routes.SIGNUP);
  void goToPasswordResetPage() => Get.toNamed(Routes.PASSWORD_RESET);
}