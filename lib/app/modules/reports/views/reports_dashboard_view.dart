import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/modules/reports/controllers/reports_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';

class ReportsDashboardView extends GetView<ReportsController> {
  const ReportsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.memberBalances.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterChips(),
              const SizedBox(height: 24),
              _buildMonthlyOverviewCard(),
              const SizedBox(height: 24),
              _buildDebtSummaryCard(),
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

  Widget _buildMonthlyOverviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Monthly Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              // This is a placeholder for the Line Chart from your design
              // A real implementation would require more complex data processing
              child: BarChart(
                BarChartData(
                  barGroups: controller.spendingByCategory.entries.map((entry) {
                    return BarChartGroupData(
                      x: controller.spendingByCategory.keys.toList().indexOf(entry.key),
                      barRods: [BarChartRodData(toY: entry.value, color: AppColors.primaryBlue, width: 16)],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Debt/Credit Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // TODO: Add the Bar Chart for this section
            const SizedBox(height: 16),
            // This list displays the final balances for each member
            ...controller.memberBalances.entries.map((entry) {
              final isOwed = entry.value > 0;
              // TODO: Get user name from UID (entry.key)
              return ListTile(
                title: Text(entry.key),
                trailing: Text(
                  "${isOwed ? 'is owed' : 'owes'} \$${entry.value.abs().toStringAsFixed(2)}",
                  style: TextStyle(color: isOwed ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.generateAndPreviewPdf,
              child: const Text("Download as PDF"),
            )
          ],
        ),
      ),
    );
  }
}