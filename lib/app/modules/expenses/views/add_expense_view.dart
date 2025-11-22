import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_controller.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';

class AddExpenseView extends GetView<ExpenseController> {
  const AddExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: controller.addExpense,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.members.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No members found in this group. Please add members first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- DESCRIPTION ---
                TextFormField(
                  controller: controller.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16.0),

                // --- AMOUNT ---
                TextFormField(
                  controller: controller.amountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ', // Placeholder currency symbol
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return 'Valid amount is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // --- DATE ---
                TextFormField(
                  controller: controller.dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: controller.selectDate,
                ),
                const SizedBox(height: 16.0),

                // --- PAID BY ---
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedPayerUid.value,
                  decoration: const InputDecoration(
                    labelText: 'Paid by',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.members.map((UserModel member) {
                    return DropdownMenuItem<String>(
                      value: member.uid,
                      child: Text(member.nickname),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.selectedPayerUid.value = newValue;
                  },
                  validator: (value) =>
                  value == null ? 'Who paid?' : null,
                )),
                const SizedBox(height: 24.0),

                // --- SPLIT METHOD SELECTION ---
                _buildSplitMethodDropdown(),

                const SizedBox(height: 16.0),

                // --- DYNAMIC SPLIT UI ---
                Obx(() {
                  String method = controller.splitMethod.value;
                  if (method == 'Split Equally' || method == 'Split by Shares') {
                    return _buildSplitBySharesUI();
                  } else if (method == 'Unequally') {
                    return _buildUnequalSplitUI();
                  } else if (method == 'Proportional') {
                    return _buildProportionalSplitInfo();
                  }
                  return const SizedBox.shrink();
                }),

                const SizedBox(height: 24.0),

                // --- CATEGORY ---
                DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: <String>[
                    'General', 'Groceries', 'Transport', 'Utilities', 'Rent',
                    'Entertainment', 'Dining Out', 'Meal', 'Shared Buy', 'Bill', 'Other',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.selectedCategory.value = newValue!;
                  },
                ),

                // --- CURRENCY (TRIP MODE ONLY) ---
                if (controller.group.type == 'Trip')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: controller.selectedCurrency.value,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Currency',
                        border: OutlineInputBorder(),
                        helperText: "Auto-converts to group's currency",
                      ),
                      items: <String>['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        controller.selectedCurrency.value = newValue!;
                      },
                    ),
                  ),

                // --- RECURRING ---
                const SizedBox(height: 16.0),
                Obx(() => SwitchListTile(
                  title: const Text('Recurring Expense?'),
                  value: controller.isRecurring.value,
                  onChanged: (val) => controller.isRecurring.value = val,
                )),

                Obx(() => Visibility(
                  visible: controller.isRecurring.value,
                  child: Column(
                    children: [
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<String>(
                        value: controller.selectedFrequency.value,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Monthly', 'Weekly', 'Quarterly', 'Yearly']
                            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                            .toList(),
                        onChanged: (val) =>
                        controller.selectedFrequency.value = val ?? 'Monthly',
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Next Due Date',
                          hintText: controller.selectedNextDueDate.value != null
                              ? DateFormat.yMMMd().format(controller.selectedNextDueDate.value!)
                              : 'Select date',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: controller.selectNextDueDate,
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    onPressed: controller.addExpense,
                    child: const Text('Add Expense', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  //                                  WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSplitMethodDropdown() {
    return Obx(() {
      final List<String> methods = ['Split Equally', 'Split by Shares', 'Unequally'];

      if (controller.group.incomeSplitRatio != null &&
          controller.group.incomeSplitRatio!.isNotEmpty) {
        methods.add('Proportional');
      }

      // Safety check
      if (!methods.contains(controller.splitMethod.value)) {
        controller.splitMethod.value = methods.first;
      }

      return DropdownButtonFormField<String>(
        value: controller.splitMethod.value,
        decoration: const InputDecoration(
          labelText: 'Split Method',
          border: OutlineInputBorder(),
        ),
        items: methods.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) controller.splitMethod.value = newValue;
        },
      );
    });
  }

  // --- NEW: UI for Unequal Splits ---
  Widget _buildUnequalSplitUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Remaining Amount Indicator
        Obx(() {
          final remaining = controller.remainingAmount.value;
          final isBalanced = remaining.abs() < 0.01;
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isBalanced ? AppColors.green.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isBalanced ? AppColors.green : AppColors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isBalanced ? AppColors.green : AppColors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isBalanced
                      ? 'Perfectly Balanced ($remaining)'
                      : 'Remaining to assign: ${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isBalanced ? AppColors.green : AppColors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.members.length,
          itemBuilder: (context, index) {
            final member = controller.members[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // Avatar or Name
                  Expanded(
                    flex: 2,
                    child: Text(
                      member.nickname,
                      style: AppTextStyles.bodyBold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Input Field
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: controller.unequalSplitControllers[member.uid],
                      decoration: const InputDecoration(
                        prefixText: '\$',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProportionalSplitInfo() {
    return Card(
      elevation: 0,
      color: AppColors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Split using saved group ratios.',
                style: AppTextStyles.bodyText1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitBySharesUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            controller.splitMethod.value == 'Split Equally'
                ? 'Select participants:'
                : 'Adjust shares:',
            style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.members.length,
          itemBuilder: (context, index) {
            final member = controller.members[index];
            return Card(
              elevation: 0,
              color: Colors.grey[50], // Subtle background
              margin: const EdgeInsets.only(bottom: 8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200)
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        member.nickname,
                        style: AppTextStyles.bodyBold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.red),
                          onPressed: () => controller.removeShare(member.uid),
                        ),
                        Obx(() => SizedBox(
                          width: 30,
                          child: Text(
                            '${controller.participantShares[member.uid] ?? 0}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title.copyWith(fontSize: 18),
                          ),
                        )),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.green),
                          onPressed: () => controller.addShare(member.uid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}