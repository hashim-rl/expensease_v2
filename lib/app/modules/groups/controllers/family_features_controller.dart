import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expensease/app/data/models/family_task_model.dart';
import 'package:expensease/app/data/models/shared_document_model.dart';
import 'package:expensease/app/data/repositories/family_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_dashboard_controller.dart';

class FamilyFeaturesController extends GetxController {
  final FamilyRepository _repository = FamilyRepository();
  // Get the group ID from the main dashboard controller
  final String groupId = Get.find<GroupDashboardController>().group.value!.id;

  final tasks = <FamilyTaskModel>[].obs;
  final documents = <SharedDocumentModel>[].obs;
  final isLoading = false.obs;

  final taskTitleController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Bind tasks and documents to live streams from the repository
    tasks.bindStream(_repository.getTasksStream(groupId));
    documents.bindStream(_repository.getDocumentsStream(groupId));
  }

  void addTask() {
    if (taskTitleController.text.isNotEmpty) {
      _repository.addTask(groupId, taskTitleController.text.trim());
      taskTitleController.clear();
    }
  }

  void toggleTaskStatus(FamilyTaskModel task) {
    _repository.updateTaskStatus(groupId, task.id, !task.isCompleted);
  }

  void uploadDocument() async {
    isLoading.value = true;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        final ref = FirebaseStorage.instance.ref('shared_documents/$groupId/$fileName');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        await _repository.saveDocumentMetadata(groupId, fileName, downloadUrl);
        Get.snackbar('Success', 'Document uploaded.');
      }
    } catch (e) {
      Get.snackbar('Error', 'File upload failed.');
    } finally {
      isLoading.value = false;
    }
  }

  void openDocument(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      Get.snackbar('Error', 'Could not open document.');
    }
  }
}