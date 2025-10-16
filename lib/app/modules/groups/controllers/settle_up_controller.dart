import 'package:get/get.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';
// --- NEW IMPORTS ---
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/modules/groups/controllers/group_controller.dart';
// -------------------

class SettleUpController extends GetxController {
  // --- NEW DEPENDENCIES ---
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final GroupController _groupController = Get.find<GroupController>();
  // ------------------------

  // CHANGED: The simplified transaction list is now an observable and calculated here
  final transactions = <SimpleTransaction>[].obs;

  // This would hold the detailed member balances (Input for DebtSimplifier)
  // Key: Member UID, Value: Net Balance (Positive = Owed, Negative = Owes)
  final memberBalances = <String, double>{}.obs;

  final isSettling = false.obs; // UI state for loading/button disable

  @override
  void onInit() {
    super.onInit();

    // UPDATED LOGIC: Expect the raw balance map (UID -> Balance) as the argument
    final Map<String, double>? rawBalances = Get.arguments as Map<String, double>?;

    if (rawBalances != null && rawBalances.isNotEmpty) {
      memberBalances.value = rawBalances;

      // CRITICAL STEP: Calculate the simplified debt structure using the utility
      transactions.value = DebtSimplifier.simplify(rawBalances);
    } else {
      // Fallback/Error state
      transactions.clear();
      memberBalances.clear();
      Get.snackbar('Error', 'No member balances found to calculate settlement.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // UPDATED: Implemented the logic to create a "payment" expense
  Future<void> recordPayment(String fromUid, String toUid, double amount) async {
    isSettling.value = true;
    final groupId = _groupController.activeGroup.value?.id;

    if (groupId == null) {
      Get.snackbar('Error', 'Cannot record payment. Group context is missing.');
      isSettling.value = false;
      return;
    }

    try {
      // Call the repository to record the payment as a special type of expense
      await _expenseRepository.addPaymentExpense(
        groupId: groupId,
        payerUid: fromUid,
        recipientUid: toUid,
        amount: amount,
      );

      // Success will automatically trigger balance updates
      Get.back(); // Close the Settle Up screen
      Get.snackbar('Success', 'Payment of \$${amount.toStringAsFixed(2)} recorded.');

    } catch (e) {
      Get.snackbar('Payment Failed', e.toString());
    } finally {
      isSettling.value = false;
    }
  }

// The simplified transactions (observable) and memberBalances (observable)
// are now exposed for the SettleUpView to display.
}