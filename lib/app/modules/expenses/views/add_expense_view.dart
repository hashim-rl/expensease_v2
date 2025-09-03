import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_controller.dart';

class AddExpenseView extends GetView<ExpenseController> {
  const AddExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isLoading.value ? 'Loading...' : 'Add Expense to ${controller.group.name}',
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: controller.addExpense,
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField(controller.descriptionController, 'Description'),
              const SizedBox(height: 16),
              _buildTextField(controller.amountController, 'Total Cost',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              _buildPayerDropdown(),
              const SizedBox(height: 24),
              _buildParticipantsCard(),
              const SizedBox(height: 24),
              _buildNotesAndPhotoSection(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: controller.addExpense,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Expense'),
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPayerDropdown() {
    // This Obx correctly rebuilds because controller.members is used directly in its builder
    return Obx(() => DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Paid by',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: controller.selectedPayerUid.value,
      items: controller.members.map((member) {
        return DropdownMenuItem(
          value: member.uid,
          child: Text(member.fullName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.selectedPayerUid.value = value;
        }
      },
    ));
  }

  Widget _buildParticipantsCard() {
    String getMemberName(String uid) {
      return controller.members
          .firstWhere((m) => m.uid == uid,
          orElse: () => UserModel(uid: uid, fullName: 'Unknown User', email: ''))
          .fullName;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Split Between',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Obx(() {
              // --- THIS IS THE FIX ---
              // We access controller.members here to ensure this Obx widget
              // rebuilds when the member list is loaded from the database.
              final _ = controller.members.length;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.participantShares.length,
                itemBuilder: (context, index) {
                  final uid = controller.participantShares.keys.elementAt(index);
                  final shares = controller.participantShares[uid]!;
                  return SwitchListTile(
                    title: Text(getMemberName(uid)),
                    subtitle: Text(shares == 2 ? 'Guest (2x Share)' : 'Normal Share'),
                    value: shares > 0,
                    onChanged: (_) => controller.toggleParticipant(uid),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesAndPhotoSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Optional notes...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Add photo/receipt',
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}