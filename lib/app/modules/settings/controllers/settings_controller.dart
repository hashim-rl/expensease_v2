import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final _box = GetStorage(); // Instance of our local storage
  final _key = 'isDarkMode'; // The key to save our setting

  // This observable will now read its initial value from storage
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // When the controller starts, load the saved preference
    isDarkMode.value = _loadThemeFromBox();
    // Apply the theme immediately
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // A method to load the saved theme setting
  bool _loadThemeFromBox() => _box.read(_key) ?? false;

  // A method to save the theme setting
  void _saveThemeToBox(bool isDarkMode) => _box.write(_key, isDarkMode);

  // This method now also saves the preference when toggled
  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    _saveThemeToBox(value);
  }

// The pickProfileImage method would typically live in a separate ProfileController
// but is kept here as per your original file.
}