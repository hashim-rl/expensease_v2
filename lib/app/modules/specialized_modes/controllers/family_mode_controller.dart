import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/models/family_task_model.dart';
import 'package:expensease/app/data/models/shared_document_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/family_repository.dart';

class FamilyModeController extends GetxController with GetTickerProviderStateMixin {
  // Repositories
  final FamilyRepository _familyRepository = Get.find<FamilyRepository>();
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();

  late final GroupModel group;
  late final TabController tabController;

  // State
  final isLoading = true.obs;
  final expenses = <ExpenseModel>[].obs;
  final tasks = <FamilyTaskModel>[].obs;
  final documents = <SharedDocumentModel>[].obs;

  final taskTitleController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    final groupArg = Get.arguments as GroupModel?;
    if (groupArg == null) {
      Get.snackbar('Error', 'No group provided for Family Mode.');
      isLoading.value = false;
      return;
    }
    group = groupArg;
    _bindStreams();
  }

  void _bindStreams() {
    expenses.bindStream(_expenseRepository.getExpensesStreamForGroup(group.id));
    tasks.bindStream(_familyRepository.getTasksStream(group.id));
    documents.bindStream(_familyRepository.getDocumentsStream(group.id));
    isLoading.value = false;
  }

  // --- Task Methods ---
  void addTask() {
    if (taskTitleController.text.isNotEmpty) {
      _familyRepository.addTask(group.id, taskTitleController.text.trim());
      taskTitleController.clear();
      Get.back(); // Close the dialog
    }
  }

  void toggleTaskStatus(FamilyTaskModel task) {
    _familyRepository.updateTaskStatus(group.id, task.id, !task.isCompleted);
  }

  // --- Document Methods ---
  void uploadDocument() async {
    isLoading.value = true;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'doc', 'png'],
      );
      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        final ref = FirebaseStorage.instance.ref('shared_documents/${group.id}/$fileName');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        await _familyRepository.saveDocumentMetadata(group.id, fileName, downloadUrl);
        Get.snackbar('Success', 'Document uploaded.');
      }
    } catch (e) {
      Get.snackbar('Error', 'File upload failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void openDocument(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open document.');
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    taskTitleController.dispose();
    super.onClose();
  }
}