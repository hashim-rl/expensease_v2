import 'package:get/get.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';

class BillsController extends GetxController {
  // Repositories
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;

  // Constructor
  BillsController({
    required GroupRepository groupRepository,
    required ExpenseRepository expenseRepository,
  })  : _groupRepository = groupRepository,
        _expenseRepository = expenseRepository; // This line was missing

  // Observables for UI state
  final isLoading = true.obs;
  final billExpenses = <ExpenseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadBillsData();
  }

  Future<void> _loadBillsData() async {
    try {
      isLoading.value = true;
      final groups = await _groupRepository.getGroupsStream().first;
      final allBills = <ExpenseModel>[];

      for (var group in groups) {
        final groupExpenses =
        await _expenseRepository.getExpensesStreamForGroup(group.id).first;
        // We will filter for a "Bill" category
        allBills.addAll(groupExpenses.where((e) => e.category == 'Bill'));
      }

      allBills.sort((a, b) => b.date.compareTo(a.date));
      billExpenses.value = allBills;

    } catch (e) {
      Get.snackbar('Error', 'Failed to load bills data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}