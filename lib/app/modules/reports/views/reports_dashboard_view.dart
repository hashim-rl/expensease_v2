import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/modules/reports/controllers/reports_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
// --- NEW IMPORT ---
import 'package:expensease/app/shared/services/user_service.dart';
// ------------------

class ReportsDashboardView extends GetView<ReportsController> {
  const ReportsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject and use the UserService to resolve UIDs to names
    final UserService userService = Get.find<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.memberBalances.isEmpty &&
            controller.spendingByCategory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterChips(),
              const SizedBox(height: 24),
              _buildMonthlyOverviewCard(context),
              const SizedBox(height: 24),
              _buildDebtSummaryCard(userService),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Obx(() => DropdownButton<GroupModel>(
            hint: const Text("Select Group"),
            value: controller.selectedGroup.value,
            items: controller.userGroups.map((group) {
              return DropdownMenuItem(value: group, child: Text(group.name));
            }).toList(),
            onChanged: (group) {
              if (group != null) {
                controller.selectedGroup.value = group;
                controller.fetchReportData();
              }
            },
          )),
          const SizedBox(width: 8),
          // Add other filters like date range here
        ],
      ),
    );
  }

  // --- UPDATED: Monthly Overview Card with Bar Chart ---
  Widget _buildMonthlyOverviewCard(BuildContext context) {
    // Collect data for the BarChart
    final spendingEntries = controller.spendingByCategory.entries.toList();
    final categories = controller.spendingByCategory.keys.toList();
    final totalSpending = controller.spendingByCategory.values.fold(
        0.0, (sum, amount) => sum + amount);

    // Only show the chart if there is data
    if (spendingEntries.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No expenses found for the selected period."),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Monthly Overview (Total: \$${totalSpending.toStringAsFixed(2)})",
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: spendingEntries
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b) *
                      1.1,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, titleMeta) {
                          final index = value.toInt();
                          if (index >= 0 && index < categories.length) {
                            return Text(
                              categories[index],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles:
                      SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: spendingEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.value,
                          color: AppColors.primaryBlue,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED: Debt Summary Card with Name Resolution ---
  Widget _buildDebtSummaryCard(UserService userService) {
    if (controller.memberBalances.isEmpty) {
      return const SizedBox.shrink(); // Hide if no data is available
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Debt/Credit Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Display the final balances for each member
            ...controller.memberBalances.entries.map((entry) {
              final uid = entry.key;
              final balance = entry.value;
              final isOwed = balance > 0;
              final color = isOwed
                  ? AppColors.green
                  : (balance < 0
                  ? AppColors.red
                  : AppColors.textPrimary);

              // CRITICAL FIX: Use FutureBuilder to resolve UID to Name
              return FutureBuilder<String>(
                future: userService.getUserName(uid),
                builder: (context, snapshot) {
                  final name = snapshot.data ??
                      (uid.length > 10 ? '${uid.substring(0, 7)}...' : uid);
                  return ListTile(
                    leading: CircleAvatar(child: Text(name.substring(0, 1))),
                    title: Text(name),
                    trailing: Text(
                      "\$${balance.abs().toStringAsFixed(2)}",
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                    Text(isOwed ? 'is owed' : (balance < 0 ? 'owes' : 'settled')),
                  );
                },
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.generateAndPreviewPdf,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue),
              child: const Text("Download as PDF",
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
