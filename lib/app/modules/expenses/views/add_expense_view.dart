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
      body: Obx(() {
        // --- THIS IS THE INTELLIGENT UI FIX ---
        // 1. Explicitly show loading state
        if (controller.isLoading.value) {
          debugPrint("--- UI TRACE: AddExpenseView is loading...");
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Handle truly empty member list with a clear message
        if (controller.members.isEmpty) {
          debugPrint("--- UI TRACE: AddExpenseView found no members.");
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
        // --- END OF UI FIX ---

        // If we have members, build the expense form.
        debugPrint("--- UI TRACE: AddExpenseView rendering with ${controller.members.length} members.");
        return SingleChildScrollView(
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
                // CRITICAL: The `Obx` widget ensures this dropdown rebuilds when `controller.members` changes.
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedPayerUid.value,
                  decoration: const InputDecoration(
                    labelText: 'Paid by',
                    border: OutlineInputBorder(),
                  ),
                  // Ensure the items list is built from the observed `controller.members`
                  items: controller.members.map((UserModel member) {
                    return DropdownMenuItem<String>(
                      value: member.uid,
                      // Use the robust `nickname` from UserModel
                      child: Text(member.nickname),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.selectedPayerUid.value = newValue;
                    debugPrint("--- UI TRACE: Payer selected: ${controller.members.firstWhereOrNull((m) => m.uid == newValue)?.nickname}");
                  },
                  // Add a validator to ensure a payer is selected
                  validator: (value) {
                    if (value == null) {
                      return 'Please select who paid';
                    }
                    return null;
                  },
                )),
                const SizedBox(height: 24.0),
                const Text(
                  'Split between',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                // Ensure this ListView also observes changes to members
                Obx(() => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.members.length,
                  itemBuilder: (context, index) {
                    final member = controller.members[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            member.nickname, // Use the robust `nickname`
                            style: const TextStyle(fontSize: 16),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => controller.removeShare(member.uid),
                              ),
                              Obx(() => Text(
                                '${controller.participantShares[member.uid] ?? 0}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              )),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => controller.addShare(member.uid),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                )),
                const SizedBox(height: 24.0),
                DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: <String>[
                    'General', 'Groceries', 'Transport', 'Utilities', 'Rent', 'Entertainment',
                    'Dining Out', 'Meal', 'Shared Buy', 'Bill', 'Other',
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
                      items: <String>[
                        'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'
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
        );
      }),
    );
  }
}