import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:expensease/app/modules/authentication/controllers/auth_controller.dart';

class SettingsController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  final isDarkMode = false.obs;
  // This will now safely find the globally available AuthController
  final AuthController authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _loadThemeFromBox();
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  bool _loadThemeFromBox() => _box.read(_key) ?? false;
  void _saveThemeToBox(bool isDarkMode) => _box.write(_key, isDarkMode);

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    _saveThemeToBox(value);
  }
}