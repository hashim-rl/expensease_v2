import 'package:get/get.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';

class SettleUpController extends GetxController {
  // The simplified transaction list is received from the previous screen
  late final List<SimpleTransaction> transactions;

  // This would also receive the detailed member balances
  final memberBalances = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Safely get the data passed as an argument
    transactions = Get.arguments as List<SimpleTransaction>;

    // TODO: The member balances map should also be passed as an argument
    // For now, we'll use mock data that reflects the design
    memberBalances.value = {
      'Sarah': -22.50,
      'Michael_owes_Sarah': 0.0, // Placeholder for a complex relation
      'Michael_owes_You': 18.00,
    };
  }

  void recordPayment(String from, String to, double amount) {
    // TODO: Implement the logic to create a "payment" transaction in Firestore.
    // This would involve calling a method in an ExpenseRepository.
    // When the payment is recorded, the balances should update automatically.
    Get.snackbar('Success', 'Payment from $from to $to for \$$amount has been recorded.');
  }
}