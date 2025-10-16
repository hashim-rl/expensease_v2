import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// --- NEW IMPORT ---
import 'package:intl/intl.dart';
// ------------------
import 'package:expensease/app/data/models/expense_model.dart';
import 'package:expensease/app/data/models/group_model.dart';
import 'package:expensease/app/data/repositories/expense_repository.dart';
import 'package:expensease/app/data/repositories/group_repository.dart';
import 'package:expensease/app/shared/utils/debt_simplifier.dart';

class ReportsController extends GetxController {
  final ExpenseRepository _expenseRepo = Get.find<ExpenseRepository>();
  final GroupRepository _groupRepo = Get.find<GroupRepository>();

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

    // Initialize all member balances to zero
    // Note: Assuming GroupModel has memberUids field based on overall structure.
    selectedGroup.value?.memberUids.forEach((memberId) {
      newBalances[memberId] = 0.0;
    });

    for (var expense in expenses) {
      final category = expense.category ?? 'Other';

      // CRITICAL FIX: Only count non-payment expenses in spending categories chart
      if (category != 'Payment') {
        newSpendingByCategory[category] = (newSpendingByCategory[category] ?? 0) + expense.totalAmount;
      }

      // Balance Calculation (applies to ALL expenses, including Payments)

      // 1. Credit the payer
      if (newBalances.containsKey(expense.paidById)) {
        newBalances[expense.paidById] = newBalances[expense.paidById]! + expense.totalAmount;
      }

      // 2. Debit the debtors (those who owe money for the expense)
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

    isLoading.value = true;
    final settlementPlan = DebtSimplifier.simplify(memberBalances.value);
    final pdf = pw.Document();

    // --- UPDATED: Add the actual PDF generation logic here using the data ---
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Monthly Report: ${selectedGroup.value!.name}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Report Date: ${DateFormat.yMMMd().format(DateTime.now())}'),

              pw.SizedBox(height: 30),

              // Spending Breakdown
              pw.Text(
                'Spending Breakdown by Category',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              ...spendingByCategory.entries.map((entry) {
                return pw.Text('${entry.key}: \$${entry.value.toStringAsFixed(2)}');
              }).toList(),

              pw.SizedBox(height: 30),

              // Settlement Plan
              pw.Text(
                'Simplified Settlement Plan',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              if (settlementPlan.isEmpty)
                pw.Text('No transfers needed. All settled!'),
              ...settlementPlan.map((t) {
                // Assuming SimpleTransaction has 'from' (UID/Name), 'to' (UID/Name), and 'amount'
                return pw.Text('${t.from} pays ${t.to} \$${t.amount.toStringAsFixed(2)}');
              }).toList(),
            ],
          );
        },
      ),
    );
    // ------------------------------------------------------------------------

    // Uses the printing package's built-in preview/save utility
    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${selectedGroup.value!.name}_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');

    isLoading.value = false;
  }
}