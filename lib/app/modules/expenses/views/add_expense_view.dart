import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_controller.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:expensease/app/shared/theme/app_colors.dart'; // <-- NEW IMPORT
import 'package:expensease/app/shared/theme/text_styles.dart'; // <-- NEW IMPORT

class AddExpenseView extends GetView<ExpenseController> {
  const AddExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: true,
        actions: [
          // Use the main addExpense method, which now handles recurring submission
          IconButton(
            onPressed: controller.addExpense,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Obx(() {
        // --- UI FIXES for Loading/Empty State ---
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
                    'No members found in this group. Please add members to the group first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        // --- END OF UI FIXES ---

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller
                .formKey, // Assuming a FormKey exists in the controller
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: controller.amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return 'Valid amount is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
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
                  validator: (value) {
                    if (value == null) return 'Please select who paid';
                    return null;
                  },
                )),
                const SizedBox(height: 24.0),

                // --- NEW SPLIT METHOD DROPDOWN ---
                _buildSplitMethodDropdown(),

                const SizedBox(height: 8.0),

                // --- CONDITIONALLY SHOW SPLIT UI ---
                Obx(() {
                  // Show the participant list for Equal and Shares
                  if (controller.splitMethod.value == 'Split Equally' ||
                      controller.splitMethod.value == 'Split by Shares') {
                    return _buildSplitBySharesUI();
                  }
                  // Show an info box for Proportional
                  if (controller.splitMethod.value == 'Proportional') {
                    return _buildProportionalSplitInfo();
                  }
                  return const SizedBox.shrink();
                }),
                // --- END OF CONDITIONAL UI ---

                const SizedBox(height: 24.0),
                DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: <String>[
                    'General',
                    'Groceries',
                    'Transport',
                    'Utilities',
                    'Rent',
                    'Entertainment',
                    'Dining Out',
                    'Meal',
                    'Shared Buy',
                    'Bill',
                    'Other',
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
                if (controller.group.type == 'Trip')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: controller.selectedCurrency.value,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
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

                // --- NEW: RECURRING EXPENSE FIELDS ---
                const SizedBox(height: 16.0),
                Obx(() => SwitchListTile(
                  title: const Text('Recurring Expense'),
                  value: controller.isRecurring.value,
                  onChanged: (bool value) {
                    controller.isRecurring.value = value;
                  },
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
                        items: [
                          'Monthly',
                          'Weekly',
                          'Quarterly',
                          'Yearly'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          controller.selectedFrequency.value =
                              newValue ?? 'Monthly';
                        },
                        validator: (value) {
                          if (controller.isRecurring.value &&
                              value == null) {
                            return 'Frequency is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        // Assumes a controller exists for this, or we display the selected date
                        decoration: InputDecoration(
                          labelText: 'Next Due Date',
                          hintText:
                          controller.selectedNextDueDate.value != null
                              ? DateFormat.yMMMd().format(
                              controller.selectedNextDueDate.value!)
                              : 'Select date',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap:
                        controller.selectNextDueDate, // Assumes this method exists
                        validator: (value) {
                          if (controller.isRecurring.value &&
                              controller.selectedNextDueDate.value ==
                                  null) {
                            return 'Next due date is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: controller
                            .whatsappNumberController, // Assumes this controller exists
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Reminder Number (Optional)',
                          hintText: '+923... (Premium Feature)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                )),
                // --- END OF NEW FIELDS ---

                const SizedBox(height: 24.0),
                Center(
                  child: ElevatedButton(
                    onPressed: controller.addExpense,
                    child: const Text('Add Expense'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // --- NEW WIDGET for Split Method Dropdown ---
  Widget _buildSplitMethodDropdown() {
    return Obx(() {
      // Build the list of available split methods
      final List<String> methods = ['Split Equally', 'Split by Shares'];
      // Conditionally add 'Proportional' if a ratio is set for the group
      if (controller.group.incomeSplitRatio != null &&
          controller.group.incomeSplitRatio!.isNotEmpty) {
        methods.add('Proportional');
      }

      // Ensure the selected value is valid, otherwise default to the first
      final String currentValue = controller.splitMethod.value;
      if (!methods.contains(currentValue)) {
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
          if (newValue != null) {
            controller.splitMethod.value = newValue;
          }
        },
      );
    });
  }

  // --- NEW WIDGET for Proportional Split Info ---
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
                'The expense will be split proportionally based on the custom ratios set for this group.',
                style: AppTextStyles.bodyText1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REFACTORED WIDGET for Share UI ---
  Widget _buildSplitBySharesUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            controller.splitMethod.value == 'Split Equally'
                ? 'Select participants to split equally:'
                : 'Adjust shares for each participant:',
            style: AppTextStyles.bodyText1
                .copyWith(color: AppColors.textSecondary),
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
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        member.nickname,
                        style: AppTextStyles.bodyBold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.red),
                          onPressed: () => controller.removeShare(member.uid),
                        ),
                        Obx(() => Text(
                          '${controller.participantShares[member.uid] ?? 0}',
                          style: AppTextStyles.title
                              .copyWith(fontSize: 18),
                        )),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.green),
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