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

  // This group object will now be updated by a stream
  final Rx<GroupModel?> group = Rx<GroupModel?>(null);
  final members = <UserModel>[].obs;

  final expenses = <ExpenseModel>[].obs;
  final memberBalances = <String, double>{}.obs;
  final isLoading = true.obs;

  StreamSubscription? _expenseSubscription;
  StreamSubscription? _groupSubscription; // NEW: For the group stream

  final currentUserNetBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Delay init to ensure Get.arguments is ready
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

    // Start listening to the group stream
    _groupSubscription?.cancel();
    _groupSubscription = _groupRepository.getGroupStream(groupArg.id).listen(
            (updatedGroup) {
          if (updatedGroup != null) {
            final bool needsMemberRefresh = group.value == null ||
                updatedGroup.memberIds.length != group.value!.memberIds.length;

            group.value = updatedGroup;

            // Only refetch members if the member list has changed
            if (needsMemberRefresh) {
              _fetchMemberDetails();
            }
          } else {
            // Handle group deletion or error
            Get.back(); // Go back if group is deleted
            Get.snackbar("Error", "Group not found.");
          }
        }, onError: (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to load group details.");
    });

    // Subscribe to expenses (can be done once)
    _subscribeToExpenses(groupArg.id);
  }

  Future<void> _fetchMemberDetails() async {
    if (group.value != null) {
      // Fetch details based on the (now-live) memberIds list
      members.value =
      await _groupRepository.getMembersDetails(group.value!.memberIds);

      // We process expense data *after* members are fetched
      // to ensure balances are calculated correctly
      _processExpenseData();
    }
  }

  void _subscribeToExpenses(String groupId) {
    _expenseSubscription?.cancel();
    _expenseSubscription = _expenseRepository
        .getExpensesStreamForGroup(groupId)
        .listen((expenseList) {
      expenses.value = expenseList;
      _processExpenseData(); // Process data when expenses change
      isLoading.value = false; // Set loading false after first load
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to load expenses.");
    });
  }

  void _processExpenseData() {
    // Don't process balances until members are loaded
    if (group.value == null || currentUserId == null || members.isEmpty) {
      return;
    }

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
    final member = members.firstWhere((m) => m.uid == uid,
        orElse: () => UserModel(
          uid: uid, // Use the UID for a better placeholder
          email: '',
          fullName: 'Unknown',
          nickname: 'Unknown User', // More specific placeholder
        ));
    return member.nickname;
  }

  @override
  void onClose() {
    _expenseSubscription?.cancel();
    _groupSubscription?.cancel(); // NEW: Cancel group sub
    super.onClose();
  }
}