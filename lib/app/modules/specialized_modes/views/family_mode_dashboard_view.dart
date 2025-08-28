import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import '../controllers/family_mode_controller.dart';

class FamilyModeDashboardView extends GetView<FamilyModeController> {
  const FamilyModeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Family Hub', style: AppTextStyles.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: controller.tabController,
          labelColor: AppColors.primaryBlue,
          indicatorColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
            Tab(icon: Icon(Icons.playlist_add_check), text: 'To-Do'),
            Tab(icon: Icon(Icons.folder_shared_outlined), text: 'Documents'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return TabBarView(
          controller: controller.tabController,
          children: [
            _buildExpenseList(),
            _buildTodoList(),
            _buildDocumentList(),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action depends on the currently selected tab
          if (controller.tabController.index == 0) {
            Get.toNamed(Routes.ADD_EXPENSE, arguments: controller.group);
          } else if (controller.tabController.index == 1) {
            _showAddTaskDialog();
          } else {
            controller.uploadDocument();
          }
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Expenses Tab ---
  Widget _buildExpenseList() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Obx(() {
      if (controller.expenses.isEmpty) {
        return const Center(child: Text('No expenses yet.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.expenses.length,
        itemBuilder: (context, index) {
          final expense = controller.expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.shopping_cart)),
              title: Text(expense.description, style: AppTextStyles.bodyBold),
              subtitle: Text('Paid on ${DateFormat.yMMMd().format(expense.date)}'),
              trailing: Text(currencyFormat.format(expense.totalAmount), style: AppTextStyles.bodyBold),
              onTap: () => Get.toNamed(Routes.EXPENSE_DETAILS, arguments: expense),
            ),
          );
        },
      );
    });
  }

  // --- To-Do Tab ---
  Widget _buildTodoList() {
    return Obx(() {
      if (controller.tasks.isEmpty) {
        return const Center(child: Text('No tasks on the to-do list.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.tasks.length,
        itemBuilder: (context, index) {
          final task = controller.tasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: CheckboxListTile(
              title: Text(
                task.title,
                style: task.isCompleted
                    ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                    : null,
              ),
              value: task.isCompleted,
              onChanged: (_) => controller.toggleTaskStatus(task),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        },
      );
    });
  }

  // --- Documents Tab ---
  Widget _buildDocumentList() {
    return Obx(() {
      if (controller.documents.isEmpty) {
        return const Center(child: Text('No shared documents.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.documents.length,
        itemBuilder: (context, index) {
          final doc = controller.documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, size: 40, color: AppColors.primaryBlue),
              title: Text(doc.fileName, style: AppTextStyles.bodyBold),
              subtitle: Text('Uploaded on ${DateFormat.yMMMd().format(doc.uploadDate.toDate())}'),
              onTap: () => controller.openDocument(doc.downloadUrl),
            ),
          );
        },
      );
    });
  }

  void _showAddTaskDialog() {
    Get.defaultDialog(
      title: 'Add New Task',
      content: TextField(
        controller: controller.taskTitleController,
        decoration: const InputDecoration(labelText: 'Task Description'),
        autofocus: true,
      ),
      confirm: ElevatedButton(
        onPressed: controller.addTask,
        child: const Text('Add'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }
}