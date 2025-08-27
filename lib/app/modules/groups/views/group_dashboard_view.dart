import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:expensease/app/modules/groups/controllers/group_dashboard_controller.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:expensease/app/shared/services/user_service.dart';
import 'package:intl/intl.dart';

class GroupDashboardView extends GetView<GroupDashboardController> {
  GroupDashboardView({super.key});

  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Obx(() => Text(controller.group.value?.name ?? 'Group')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Group Settings",
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed(
              Routes.MEMBERS_PERMISSIONS,
              arguments: controller.group.value,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildGroupHeaderCard(),
              const TabBar(
                tabs: [
                  Tab(text: 'Expenses'),
                  Tab(text: 'Balances'),
                ],
                labelColor: Colors.black87,
                indicatorColor: Colors.blueAccent,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildExpenseList(),
                    _buildBalancesView(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(
          Routes.ADD_EXPENSE,
          arguments: controller.group.value,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Obx(() => _summaryItem("Total Spent",
              "\$${controller.totalGroupSpent.value.toStringAsFixed(2)}")),
          const SizedBox(
            height: 50,
            child: VerticalDivider(),
          ),
          Obx(() => _summaryItem("Your Share",
              "\$${controller.currentUserShare.value.toStringAsFixed(2)}")),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    return Obx(() {
      if (controller.expenses.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'No Expenses Here',
          subtitle: 'Tap the (+) button to add the first expense to this group.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.expenses.length,
        itemBuilder: (context, index) {
          final expense = controller.expenses[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                leading: const CircleAvatar(
                  child: Icon(Icons.shopping_cart_outlined),
                ),
                title: Text(expense.description,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: FutureBuilder<String>(
                  future: _userService.getUserName(expense.paidById),
                  builder: (context, snapshot) {
                    return Text(
                        'Paid by ${snapshot.data ?? "..."} on ${DateFormat.yMMMd().format(expense.date)}');
                  },
                ),
                trailing: Text('\$${expense.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () =>
                    Get.toNamed(Routes.EXPENSE_DETAILS, arguments: expense),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBalancesView() {
    return Obx(() {
      final balances = controller.memberBalances.entries.toList();
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: balances.length,
        itemBuilder: (context, index) {
          final entry = balances[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: FutureBuilder<String>(
                future: _userService.getUserName(entry.key),
                builder: (context, snapshot) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      child: Text(snapshot.data?.substring(0, 1) ?? '?'),
                    ),
                    title: Text(snapshot.data ?? 'Loading...',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      '${entry.value < 0 ? '-' : ''}\$${entry.value.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: entry.value >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    });
  }
}