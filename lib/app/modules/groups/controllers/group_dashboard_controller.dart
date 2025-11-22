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

  // Map of UserID -> Net Balance
  final memberBalances = <String, double>{}.obs;
  final isLoading = true.obs;

  StreamSubscription? _expenseSubscription;
  StreamSubscription? _groupSubscription;

  final currentUserNetBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(Duration.zero, () {
      _initializeDashboard();
    });
  }

  void _initializeDashboard() {
    final groupArg = Get.arguments as GroupModel?;
    if (groupArg == null) {
      isLoading.value = false;
      Get.snackbar("Error", "Could not load group data. Please go back.");
      return;
    }

    _groupSubscription?.cancel();
    _groupSubscription = _groupRepository.getGroupStream(groupArg.id).listen(
            (updatedGroup) {
          if (updatedGroup != null) {
            final bool needsMemberRefresh = group.value == null ||
                updatedGroup.memberIds.length != group.value!.memberIds.length;

            group.value = updatedGroup;

            if (needsMemberRefresh) {
              _fetchMemberDetails();
            }
          } else {
            Get.back();
            Get.snackbar("Error", "Group not found.");
          }
        }, onError: (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to load group details.");
    });

    _subscribeToExpenses(groupArg.id);
  }

  Future<void> _fetchMemberDetails() async {
    if (group.value != null) {
      members.value =
      await _groupRepository.getMembersDetails(group.value!.memberIds);
      _processExpenseData();
    }
  }

  void _subscribeToExpenses(String groupId) {
    _expenseSubscription?.cancel();
    _expenseSubscription = _expenseRepository
        .getExpensesStreamForGroup(groupId)
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
    // We can calculate balances even if member details aren't fully loaded yet,
    // but we need the current User ID.
    if (currentUserId == null) return;

    // Initialize balances with 0.0 for current members
    final newBalances = <String, double>{};
    for (var member in members) {
      newBalances[member.uid] = 0.0;
    }

    for (var expense in expenses) {
      // 1. Payer gains credit (+)
      // If the payer left the group, we still track them (add to map if missing)
      newBalances[expense.paidById] = (newBalances[expense.paidById] ?? 0.0) + expense.totalAmount;

      // 2. Participants accumulate debt (-)
      for (var entry in expense.splitBetween.entries) {
        final participantId = entry.key;
        final share = entry.value;

        // Subtract share from their balance
        newBalances[participantId] = (newBalances[participantId] ?? 0.0) - share;
      }
    }

    memberBalances.value = newBalances;
    currentUserNetBalance.value = newBalances[currentUserId] ?? 0.0;
  }

  String getMemberName(String uid) {
    // Try to find in current members
    final member = members.firstWhere((m) => m.uid == uid,
        orElse: () => UserModel(
          uid: uid,
          email: '',
          fullName: 'Unknown',
          nickname: 'Past Member', // Better fallback for people who left
        ));
    return member.nickname;
  }

  // --- NEW: Helper for View to get Currency ---
  String getGroupCurrency() {
    return group.value?.currency ?? 'USD';
  }

  @override
  void onClose() {
    _expenseSubscription?.cancel();
    _groupSubscription?.cancel();
    super.onClose();
  }
}