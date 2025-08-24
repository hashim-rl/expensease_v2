import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';
import 'package:expensease/app/shared/widgets/auth_background.dart';
import 'package:expensease/app/routes/app_routes.dart';
// Removed AppColors import as it's not defined yet
import 'package:expensease/app/shared/utils/validators.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: controller.logInFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                _buildTextFormField(
                  controller: controller.emailController,
                  hint: 'Email Address',
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: controller.passwordController,
                  hint: 'Password',
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.toNamed(Routes.PASSWORD_RESET),
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLoginButton(),
                const SizedBox(height: 24),
                const Text('Or log in with',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                _buildSocialButtons(),
                const SizedBox(height: 24),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?)? validator,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        // FIX: Replaced AppColors.errorColor with a standard color
        errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildLoginButton() {
    return Obx(
          () => ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.logIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E), // Dark button
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: controller.isLoading.value
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        )
            : const Text('Log In', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () {
              // TODO: Implement Google Sign In
            },
            icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white)),
        const SizedBox(width: 24),
        IconButton(
            onPressed: () {
              // TODO: Implement Apple Sign In
            },
            icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white)),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ",
            style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: controller.goToSignupPage,
          child: const Text("Sign Up",
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}