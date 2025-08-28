import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/settings/controllers/edit_profile_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile', style: AppTextStyles.title)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.currentUser.value == null) {
          return const Center(child: Text('Could not load user data.'));
        }

        final user = controller.currentUser.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Obx(() => CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: controller.profilePicUrl.value.isNotEmpty
                        ? NetworkImage(controller.profilePicUrl.value)
                        : null,
                    child: controller.profilePicUrl.value.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  )),
                  Positioned(
                    bottom: 0,
                    right: MediaQuery.of(context).size.width / 2 - 80,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      child: IconButton(
                        onPressed: controller.pickAndUploadProfileImage,
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: controller.fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: controller.updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button.copyWith(color: Colors.white),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      }),
    );
  }
}