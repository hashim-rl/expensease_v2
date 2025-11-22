import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:expensease/app/shared/widgets/list_shimmer_loader.dart';
import 'package:animate_do/animate_do.dart';
import 'package:expensease/app/data/models/group_model.dart';

class GroupsListView extends GetView<GroupController> {
  const GroupsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ListShimmerLoader();
        }
        if (controller.groups.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.groups_2_outlined,
            title: 'No Groups Yet',
            subtitle:
            'Tap the (+) button at the bottom to create your first shared group!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.groups.length,
          itemBuilder: (context, index) {
            final group = controller.groups[index];
            final balance = controller.groupBalances[group.id] ?? 0.0;
            return _buildGroupCard(group, balance);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group, double balance) {
    // Simple helper to get symbol based on currency code
    String getCurrencySymbol(String? code) {
      if (code == 'EUR') return '€';
      if (code == 'GBP') return '£';
      if (code == 'JPY') return '¥';
      return '\$';
    }

    final symbol = getCurrencySymbol(group.currency);

    return FadeInUp(
      delay: Duration(milliseconds: 100 * (group.hashCode % 10)),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 4,
        child: InkWell(
          onTap: () => Get.toNamed(
            Routes.GROUP_DASHBOARD,
            arguments: group,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  group.coverPhotoUrl ??
                      'https://images.unsplash.com/photo-1588421357574-87938a86fa28?w=800',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(group.type,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${balance < 0 ? '-' : ''}$symbol${balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Your Balance',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    controller.groupNameController.clear();
    // Reset selection to defaults
    controller.selectedGroupType.value = 'Flatmates';
    controller.selectedCurrency.value = 'USD';

    Get.dialog(
      AlertDialog(
        title: const Text('Create a New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 20),
            // Group Type Dropdown
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedGroupType.value,
              decoration: const InputDecoration(
                labelText: 'Group Type',
                border: OutlineInputBorder(),
              ),
              items: ['Flatmates', 'Friends', 'Trip']
                  .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  controller.selectedGroupType.value = newValue;
                }
              },
            )),

            // --- NEW: Conditional Currency Dropdown ---
            Obx(() {
              if (controller.selectedGroupType.value == 'Trip') {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedCurrency.value,
                    decoration: const InputDecoration(
                      labelText: 'Group Currency',
                      border: OutlineInputBorder(),
                      helperText: 'All expenses will convert to this',
                    ),
                    items: ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD']
                        .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        controller.selectedCurrency.value = newValue;
                      }
                    },
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
            // ------------------------------------------
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: controller.createGroup, child: const Text('Create')),
        ],
      ),
    );
  }
}