import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/family_features_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';

class FamilyTodoView extends GetView<FamilyFeaturesController> {
  const FamilyTodoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: controller.taskTitleController,
            decoration: InputDecoration(
              hintText: 'Add a new household task...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: controller.addTask,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.tasks.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.checklist,
                title: 'No Tasks Yet',
                subtitle: 'Add a task above to get started.',
              );
            }
            return ListView.builder(
              itemCount: controller.tasks.length,
              itemBuilder: (context, index) {
                final task = controller.tasks[index];
                return CheckboxListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.grey : null,
                    ),
                  ),
                  value: task.isCompleted,
                  onChanged: (val) => controller.toggleTaskStatus(task),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            );
          }),
        ),
      ],
    );
  }
}