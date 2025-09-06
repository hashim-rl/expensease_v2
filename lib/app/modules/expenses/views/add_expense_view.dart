import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_controller.dart';
import 'package:expensease/app/data/models/user_model.dart';

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
      body: Obx(
            () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: controller.amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                DropdownButtonFormField<String>(
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
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Split between',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                // --- THIS IS THE FIX & NEW FEATURE ---
                // This ListView builder creates a row for each member
                // with buttons to add/remove shares.
                Obx(() {
                  if (controller.members.isEmpty) {
                    return const Center(
                        child: Text("No members found in this group."));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.members.length,
                    itemBuilder: (context, index) {
                      final member = controller.members[index];
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              member.nickname,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline),
                                  onPressed: () => controller
                                      .removeShare(member.uid),
                                ),
                                Obx(() => Text(
                                  '${controller.participantShares[member.uid] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )),
                                IconButton(
                                  icon: const Icon(
                                      Icons.add_circle_outline),
                                  onPressed: () =>
                                      controller.addShare(member.uid),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 24.0),
                DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  // --- FIX STARTS HERE ---
                  // Added 'Shared Buy' and 'Bill' to the list of items
                  // so the app won't crash when you navigate from those tabs.
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
                  // --- FIX ENDS HERE ---
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
                      items: <String>[
                        'USD',
                        'EUR',
                        'GBP',
                        'JPY',
                        'CAD',
                        'AUD'
                      ].map<DropdownMenuItem<String>>((String value) {
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
                SwitchListTile(
                  title: const Text('Recurring Expense'),
                  value: controller.isRecurring.value,
                  onChanged: (bool value) {
                    controller.isRecurring.value = value;
                  },
                ),
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
        ),
      ),
    );
  }
}