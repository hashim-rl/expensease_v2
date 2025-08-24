import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/expenses/controllers/expense_controller.dart';
import 'package:expensease/app/shared/services/user_service.dart';

class AddExpenseView extends GetView<ExpenseController> {
  const AddExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expense to ${controller.group.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: controller.addExpense,
          )
        ],
      ),
      body: Obx(() {
        return controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
    final UserService userService = UserService();
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Bought by',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: controller.selectedPayerUid.value,
      // THIS IS THE FIX: We now map over group.memberIds
      items: controller.group.memberIds.map((uid) {
        return DropdownMenuItem(
          value: uid,
          // Use a FutureBuilder to get the name for each ID
          child: FutureBuilder<String>(
            future: userService.getUserName(uid),
            builder: (context, snapshot) {
              return Text(snapshot.data ?? 'Loading...');
            },
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.selectedPayerUid.value = value;
        }
      },
    );
  }

  Widget _buildParticipantsCard() {
    final UserService userService = UserService();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Participants',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.participantShares.length,
              itemBuilder: (context, index) {
                final uid = controller.participantShares.keys.elementAt(index);
                final shares = controller.participantShares[uid]!;

                return FutureBuilder<String>(
                  future: userService.getUserName(uid),
                  builder: (context, snapshot) {
                    return SwitchListTile(
                      secondary: Checkbox(
                        value: shares > 0,
                        onChanged: (_) => controller.toggleParticipant(uid),
                      ),
                      title: Text(snapshot.data ?? '...'),
                      subtitle: Text(shares == 2 ? 'Guest (2x Share)' : 'Normal Share'),
                      value: shares == 2,
                      onChanged: shares > 0 ? (_) => controller.toggleGuestStatus(uid) : null,
                    );
                  },
                );
              },
            )),
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