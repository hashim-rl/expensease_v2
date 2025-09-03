import 'package:get/get.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';

class SharedBuysController extends GetxController {
  // Repositories
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  // Constructor
  SharedBuysController({
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _groupRepository = groupRepository,
        _expenseRepository = expenseRepository;

  // Observables for UI state
  final isLoading = true.obs;
  final sharedBuyExpenses = <ExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSharedBuysData();
  }

  Future<void> _loadSharedBuysData() async {
    try {
      isLoading.value = true;
      final groups = await _groupRepository.getGroupsStream().first;
      final allSharedBuys = <ExpenseModel>[];

      for (var group in groups) {
        final groupExpenses =
        await _expenseRepository.getExpensesStreamForGroup(group.id).first;
        // We will filter for a "Shared Buy" category
        allSharedBuys
            .addAll(groupExpenses.where((e) => e.category == 'Shared Buy'));
      }

      allSharedBuys.sort((a, b) => b.date.compareTo(a.date));
      sharedBuyExpenses.value = allSharedBuys;

    } catch (e) {
      Get.snackbar('Error', 'Failed to load shared buys data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}