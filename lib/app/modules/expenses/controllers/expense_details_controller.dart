import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/comment_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/services/auth_service.dart';

class ExpenseDetailsController extends GetxController {
  final ExpenseRepository _expenseRepository;
  final AuthService _authService;
  final GroupController _groupController;

  ExpenseDetailsController({
    required ExpenseRepository expenseRepository,
    required AuthService authService,
    required GroupController groupController,
  })  : _expenseRepository = expenseRepository,
        _authService = authService,
        _groupController = groupController;

  late final ExpenseModel expense;

  final commentController = TextEditingController();
  final comments = <CommentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    expense = Get.arguments as ExpenseModel;

    final groupId = _groupController.activeGroup.value?.id;
    if (groupId != null) {
      comments.bindStream(_expenseRepository.getCommentsStreamForExpense(
        groupId,
        expense.id,
      ));
    }
  }

  void postComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    final groupId = _groupController.activeGroup.value?.id;
    final authorUid = _authService.currentUserId;

    if (groupId == null || authorUid == null) {
      Get.snackbar('Error', 'Cannot post comment. Group or user data missing.');
      return;
    }

    try {
      await _expenseRepository.addComment(
        groupId: groupId,
        expenseId: expense.id,
        authorUid: authorUid,
        text: text,
      );
      commentController.clear();
    } catch (e) {
      Get.snackbar('Comment Failed', 'Could not post comment: $e');
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
