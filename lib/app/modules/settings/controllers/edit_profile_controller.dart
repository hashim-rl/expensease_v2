import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/repositories/user_repository.dart';

class EditProfileController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();

  final fullNameController = TextEditingController();
  final isLoading = false.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final profilePicUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    isLoading.value = true;
    currentUser.value = await _userRepository.getCurrentUser();
    if (currentUser.value != null) {
      fullNameController.text = currentUser.value!.fullName;
      profilePicUrl.value = currentUser.value!.profilePicUrl ?? '';
    }
    isLoading.value = false;
  }

  Future<void> pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      isLoading.value = true;
      final newImageUrl = await _userRepository.uploadProfilePicture(image);
      if (newImageUrl != null) {
        profilePicUrl.value = newImageUrl;
        Get.snackbar('Success', 'Profile picture updated!');
      } else {
        Get.snackbar('Error', 'Failed to upload image.');
      }
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (fullNameController.text.isEmpty) {
      Get.snackbar('Error', 'Name cannot be empty.');
      return;
    }
    isLoading.value = true;
    await _userRepository.updateUserName(fullNameController.text.trim());
    isLoading.value = false;
    Get.snackbar('Success', 'Profile updated successfully!');
    // Go back and signal that the profile was updated
    Get.back(result: true);
  }

  @override
  void onClose() {
    fullNameController.dispose();
    super.onClose();
  }
}