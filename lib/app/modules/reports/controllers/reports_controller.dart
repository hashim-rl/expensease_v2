import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';

class ReportsController extends GetxController {
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final GroupRepository _groupRepo = GroupRepository();

  final selectedGroup = Rx<GroupModel?>(null);
  final userGroups = <GroupModel>[].obs;
  final isLoading = false.obs;
  final spendingByCategory = <String, double>{}.obs;
  final memberBalances = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserGroups();
  }

  void fetchUserGroups() async {
    _groupRepo.getGroupsStream().listen((groups) {
      userGroups.value = groups;
      if (groups.isNotEmpty && selectedGroup.value == null) {
        selectedGroup.value = groups.first;
        fetchReportData();
      }
    });
  }

  void fetchReportData({String dateRange = 'This Month'}) async {
    if (selectedGroup.value == null) return;
    isLoading.value = true;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    final expenses = await _expenseRepo.getExpensesForReport(
      groupId: selectedGroup.value!.id,
      startDate: startDate,
      endDate: endDate,
    );
    _calculateSummary(expenses);
    isLoading.value = false;
  }

  void _calculateSummary(List<ExpenseModel> expenses) {
    final newBalances = <String, double>{};
    final newSpendingByCategory = <String, double>{};

    selectedGroup.value?.memberIds.forEach((memberId) {
      newBalances[memberId] = 0.0;
    });

    for (var expense in expenses) {
      final category = expense.category ?? 'Other';
      newSpendingByCategory[category] = (newSpendingByCategory[category] ?? 0) + expense.totalAmount;

      // FIX 1: Renamed paidBy to paidById
      if (newBalances.containsKey(expense.paidById)) {
        newBalances[expense.paidById] = newBalances[expense.paidById]! + expense.totalAmount;
      }
      // FIX 2: Renamed split to splitBetween
      for (var entry in expense.splitBetween.entries) {
        if (newBalances.containsKey(entry.key)) {
          newBalances[entry.key] = newBalances[entry.key]! - entry.value;
        }
      }
    }
    spendingByCategory.value = newSpendingByCategory;
    memberBalances.value = newBalances;
  }

  Future<void> generateAndPreviewPdf() async {
    if (selectedGroup.value == null || memberBalances.isEmpty) {
      Get.snackbar('Error', 'No data available to generate a report.');
      return;
    }

    final settlementPlan = DebtSimplifier.simplify(memberBalances);
    final pdf = pw.Document();

    // TODO: Add the actual PDF generation logic here using the data

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}