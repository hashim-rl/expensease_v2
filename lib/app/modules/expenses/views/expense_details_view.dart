import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_details_controller.dart';
import 'package:expensease/app/shared/services/user_service.dart';
// Removed AppColors import as it's not used

class ExpenseDetailsView extends GetView<ExpenseDetailsController> {
  const ExpenseDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Moved UserService initialization outside of build for cleaner structure
    // But since it's a GetView, we can just use Get.find<UserService>() if it's bound
    final UserService userService = Get.find<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.expense.description),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(userService),
                const SizedBox(height: 24),
                Text('Participants', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                _buildParticipantsList(userService),
                const SizedBox(height: 24),
                Text('Comments', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                _buildCommentsList(userService), // PASS USER SERVICE HERE
              ],
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(UserService userService) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('TOTAL', style: TextStyle(color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(
              '\$${controller.expense.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              // FIX 1: Renamed paidBy to paidById
              future: userService.getUserName(controller.expense.paidById),
              builder: (context, snapshot) {
                return Text(
                  'Paid by ${snapshot.data ?? '...'} on ${DateFormat.yMMMd().format(controller.expense.date)}',
                  style: const TextStyle(color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(UserService userService) {
    // FIX 2: Renamed split to splitBetween
    final participants = controller.expense.splitBetween.entries.toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final entry = participants[index];
          return FutureBuilder<String>(
            future: userService.getUserName(entry.key),
            builder: (context, snapshot) {
              return ListTile(
                leading: CircleAvatar(child: Text(snapshot.data?.substring(0, 1) ?? '?')),
                title: Text(snapshot.data ?? 'Loading...'),
                trailing: Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
        separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16, height: 1),
      ),
    );
  }

  // --- UPDATED METHOD SIGNATURE AND IMPLEMENTATION ---
  Widget _buildCommentsList(UserService userService) {
    return Obx(() {
      if (controller.comments.isEmpty) {
        return const Text("No comments yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey));
      }
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListView.builder(
          reverse: true, // Display newest comment at the bottom
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.comments.length,
          itemBuilder: (context, index) {
            final comment = controller.comments[index];
            return FutureBuilder<String>(
              // NEW: Use the authorUid from the CommentModel to fetch the name
              future: userService.getUserName(comment.authorUid),
              builder: (context, snapshot) {
                final authorName = snapshot.data ?? 'A user';
                return ListTile(
                  title: Text(comment.text),
                  // NEW: Display the author's name and the comment timestamp
                  subtitle: Text(
                    '$authorName • ${DateFormat('MMM d, h:mm a').format(comment.timestamp)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }
  // ----------------------------------------------------

  Widget _buildCommentInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller.commentController,
        decoration: InputDecoration(
          hintText: 'Add a comment...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: controller.postComment,
          ),
        ),
      ),
    );
  }
}