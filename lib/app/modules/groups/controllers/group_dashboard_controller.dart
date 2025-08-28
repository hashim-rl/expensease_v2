import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/models/user_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';

class GroupDashboardController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final GroupRepository _groupRepository = Get.find<GroupRepository>();

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final Rx<GroupModel?> group = Rx<GroupModel?>(null);
  final members = <UserModel>[].obs;

  final expenses = <ExpenseModel>[].obs;
  final memberBalances = <String, double>{}.obs;
  final isLoading = true.obs;
  StreamSubscription? _expenseSubscription;

  final currentUserNetBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final groupArg = Get.arguments as GroupModel?;
    if (groupArg == null) {
      isLoading.value = false;
      Get.snackbar("Error", "Could not load group data. Please go back.");
      return;
    }
    group.value = groupArg;
    _fetchMemberDetailsAndExpenses();
  }

  Future<void> _fetchMemberDetailsAndExpenses() async {
    isLoading.value = true;
    if (group.value != null) {
      members.value =
      await _groupRepository.getMembersDetails(group.value!.memberIds);
      _subscribeToExpenses();
    } else {
      isLoading.value = false;
    }
  }

  void _subscribeToExpenses() {
    _expenseSubscription?.cancel();
    _expenseSubscription = _expenseRepository
        .getExpensesStreamForGroup(group.value!.id)
        .listen((expenseList) {
      expenses.value = expenseList;
      _processExpenseData();
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to load expenses.");
    });
  }

  void _processExpenseData() {
    if (group.value == null || currentUserId == null) return;

    final newBalances = {for (var member in members) member.uid: 0.0};

    for (var expense in expenses) {
      if (newBalances.containsKey(expense.paidById)) {
        newBalances[expense.paidById] =
            newBalances[expense.paidById]! + expense.totalAmount;
      }
      for (var entry in expense.splitBetween.entries) {
        final participantId = entry.key;
        final share = entry.value;
        if (newBalances.containsKey(participantId)) {
          newBalances[participantId] = newBalances[participantId]! - share;
        }
      }
    }

    memberBalances.value = newBalances;
    currentUserNetBalance.value = newBalances[currentUserId] ?? 0.0;
  }

  String getMemberName(String uid) {
    // This is the corrected part
    final member = members.firstWhere((m) => m.uid == uid,
        orElse: () =>
            UserModel(uid: '', email: '', fullName: 'Unknown'));
    return member.fullName;
  }

  @override
  void onClose() {
    _expenseSubscription?.cancel();
    super.onClose();
  }
}