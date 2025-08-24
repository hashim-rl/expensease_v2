import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/repositories/auth_repository.dart';
import 'package:expensease/app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _repository = Get.find<AuthRepository>();

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

  // ✅ FIX: All startup logic (onReady, listeners, etc.) has been REMOVED.
  // The SplashView now handles this.

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.onClose();
  }

  Future<void> signUp() async {
    final isValid = signUpFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    isLoading.value = true;
    try {
      final userCredential = await _repository.signUpWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        await _repository.createUserDocument(
          userCredential.user!,
          fullNameController.text.trim(),
        );
      }
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