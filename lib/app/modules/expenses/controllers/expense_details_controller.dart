import 'package:flutter/material.dart';
import 'package:get/get.dart';
// --- NEW IMPORTS ---
import 'package:expensease/app/data/models/comment_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/services/auth_service.dart';
// -------------------

class ExpenseDetailsController extends GetxController {
  // --- NEW FIELDS ---
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final AuthService _authService = Get.find<AuthService>();
  final GroupController _groupController = Get.find<GroupController>();
  // ------------------

  // The ExpenseModel is received from the previous screen
  late final ExpenseModel expense;

  final commentController = TextEditingController();
  // CHANGED: Now holds a list of structured CommentModel objects
  final comments = <CommentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Safely get the expense data passed as an argument
    expense = Get.arguments as ExpenseModel;

    // --- UPDATED: Bind comments to a live stream ---
    final groupId = _groupController.activeGroup.value?.id;
    if (groupId != null) {
      comments.bindStream(_expenseRepository.getCommentsStreamForExpense(
        groupId,
        expense.id,
      ));
    }
    // ---------------------------------------------
  }

  void postComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    // Check for necessary data before posting
    final groupId = _groupController.activeGroup.value?.id;
    final authorUid = _authService.currentUser.value?.uid;

    if (groupId == null || authorUid == null) {
      Get.snackbar('Error', 'Cannot post comment. Group or user data missing.');
      return;
    }

    try {
      // --- UPDATED LOGIC: Save the new comment to Firestore ---
      await _expenseRepository.addComment(
        groupId: groupId,
        expenseId: expense.id,
        authorUid: authorUid,
        text: text,
      );
      commentController.clear();
      // Since `comments` is bound to a stream, the new comment will appear automatically.
    } catch (e) {
      Get.snackbar('Comment Failed', 'Could not post comment: $e');
    }
    // --------------------------------------------------------
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}