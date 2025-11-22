import 'package:get/get.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/user_model.dart';

class SettleUpController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();

  final transactions = <SimpleTransaction>[].obs;
  final isSettling = false.obs;

  // Local context data
  late GroupModel group;
  late List<UserModel> members;

  // Raw balances for reference
  final memberBalances = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() {
    final args = Get.arguments as Map<String, dynamic>?;

    if (args == null) {
      Get.snackbar('Error', 'Initialization failed. No arguments passed.');
      return;
    }

    try {
      // 1. Extract Context
      group = args['group'] as GroupModel;
      members = args['members'] as List<UserModel>;
      final balances = args['balances'] as Map<String, double>;

      memberBalances.value = balances;

      // 2. Calculate Simplified Debts
      if (balances.isNotEmpty) {
        transactions.value = DebtSimplifier.simplify(balances);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load settlement data: $e');
    }
  }

  Future<void> recordPayment(String fromUid, String toUid, double amount) async {
    isSettling.value = true;

    try {
      await _expenseRepository.addPaymentExpense(
        groupId: group.id,
        payerUid: fromUid,
        recipientUid: toUid,
        amount: amount,
      );

      Get.back();
      Get.snackbar('Success', 'Payment recorded successfully.');
    } catch (e) {
      Get.snackbar('Payment Failed', e.toString());
    } finally {
      isSettling.value = false;
    }
  }

  // --- Helpers for the View ---

  String getCurrency() {
    return group.currency ?? 'USD';
  }

  String getMemberName(String uid) {
    final member = members.firstWhere(
          (m) => m.uid == uid,
      orElse: () => UserModel(uid: uid, email: '', fullName: 'Unknown', nickname: 'User'),
    );
    return member.nickname;
  }
}