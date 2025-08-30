import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/widgets/app_drawer.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: controller.openDrawer,
        ),
        title: const Text('ExpensEase'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => Get.toNamed(Routes.PROFILE),
              child: const CircleAvatar(
                child: Icon(Icons.person_outline),
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            _buildTotalBalanceCard(),
            const TabBar(
              tabs: [
                Tab(text: "Reports"),
                Tab(text: "Meals"),
                Tab(text: "Shared Buys"),
                Tab(text: "Bills"),
              ],
              labelColor: Colors.black,
              indicatorColor: AppColors.primaryBlue,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // --- THIS IS THE FIX ---
                  // The summary content is now the last item, matching the "Reports" tab.
                  _buildSummaryContent(),
                  const Center(child: Text("Meals Data Coming Soon")),
                  const Center(child: Text("Shared Buys Data Coming Soon")),
                  const Center(child: Text("Bills Data Coming Soon")),
                   // Moved to the last position
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF84fab0), Color(0xFF8fd3f4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your Total Balance",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Obx(() => Text(
            "\$${controller.overallBalance.value.toStringAsFixed(2)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("This Month Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                child: Obx(() => PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 70,
                    sections: controller.pieChartSections.value,
                    startDegreeOffset: -90,
                  ),
                )),
              ),
              _buildAddButton(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.lightBlue, "Paid"),
        const SizedBox(width: 24),
        _legendItem(Colors.orangeAccent, "Owed"),
        const SizedBox(width: 24),
        _legendItem(Colors.pinkAccent, "Due"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildAddButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'create_group') {
          Get.toNamed(Routes.GROUPS_LIST);
        } else {
          _showGroupSelectionDialog();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'bill',
          child:
          ListTile(leading: Icon(Icons.receipt_long), title: Text('Add Bill')),
        ),
        const PopupMenuItem<String>(
          value: 'meal',
          child:
          ListTile(leading: Icon(Icons.restaurant), title: Text('Add Meal')),
        ),
        const PopupMenuItem<String>(
          value: 'expense',
          child: ListTile(
              leading: Icon(Icons.shopping_cart), title: Text('Add Expense')),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'create_group',
          child: ListTile(
              leading: Icon(Icons.group_add_outlined),
              title: Text('Create or Join Group')),
        ),
      ],
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 40, color: Colors.grey),
      ),
    );
  }

  void _showGroupSelectionDialog() {
    if (controller.groups.isEmpty) {
      Get.snackbar(
          "No Groups Available", "Create a group before adding an expense.");
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Select a Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() => ListView.builder(
            shrinkWrap: true,
            itemCount: controller.groups.length,
            itemBuilder: (context, index) {
              final group = controller.groups[index];
              return ListTile(
                title: Text(group.name),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.ADD_EXPENSE, arguments: group);
                },
              );
            },
          )),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
        ],
      ),
    );
  }
}