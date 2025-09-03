import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/dashboard/controllers/dashboard_controller.dart'; // Import DashboardController
import 'package:expensease/app/modules/meal/controllers/meal_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';

class MealView extends GetView<MealController> {
  const MealView({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the DashboardController to access the reusable dialog
    final DashboardController dashboardController = Get.find<DashboardController>();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSummarySection(),
            _buildRecentMealsHeader(),
            Expanded(child: _buildRecentMealsList()),
          ],
        );
      }),
      // --- THIS IS THE ACTUAL FIX ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call the reusable dialog from the DashboardController and pass 'Meal' as the category
          dashboardController.showGroupSelectionDialog(category: 'Meal');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Builds the top section with summary cards
  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              title: 'Total Meals',
              value: controller.totalMeals.value.toString(),
              icon: Icons.restaurant_menu,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _summaryCard(
              title: 'Total Cost',
              value: '\$${controller.totalMealCost.value.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _summaryCard(
              title: 'Avg Cost',
              value: '\$${controller.averageMealCost.value.toStringAsFixed(2)}',
              icon: Icons.pie_chart,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // A reusable widget for the summary cards
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Builds the "Recent Meals" header
  Widget _buildRecentMealsHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Meals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Builds the list of recent meals
  Widget _buildRecentMealsList() {
    if (controller.recentMeals.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.no_food,
        title: 'No Meals Logged',
        subtitle: 'Tap the + button to add your first meal expense!',
      );
    }

    return Obx(
          () => ListView.builder(
        itemCount: controller.recentMeals.length,
        itemBuilder: (context, index) {
          final meal = controller.recentMeals[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.restaurant),
              ),
              title: Text(
                meal.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat.yMMMd().format(meal.date),
              ),
              trailing: Text(
                '\$${meal.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}