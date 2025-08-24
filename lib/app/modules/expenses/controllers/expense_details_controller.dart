import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/expense_model.dart';

class ExpenseDetailsController extends GetxController {
  // The ExpenseModel is received from the previous screen
  late final ExpenseModel expense;

  final commentController = TextEditingController();
  // This would hold a live list of comments for the expense
  final comments = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Safely get the expense data passed as an argument
    expense = Get.arguments as ExpenseModel;

    // TODO: Fetch comments for this expense from a sub-collection in Firestore
    // For now, we'll use mock comments
    comments.value = ["Hey, I think you missed adding the tip.", "Oh, you're right! I'll create a separate expense for that."];
  }

  void postComment() {
    if (commentController.text.isNotEmpty) {
      // TODO: Add logic to save the new comment to Firestore
      comments.add(commentController.text);
      commentController.clear();
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}