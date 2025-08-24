// Defines a simple transaction data class.
class SimpleTransaction {
  final String from;
  final String to;
  final double amount;

  SimpleTransaction({required this.from, required this.to, required this.amount});

  @override
  String toString() {
    return '$from pays $to \$${amount.toStringAsFixed(2)}';
  }
}

// Implements the debt simplification algorithm.
class DebtSimplifier {
  static List<SimpleTransaction> simplify(Map<String, double> memberBalances) {
    // Separate members into debtors (owe money) and creditors (are owed money).
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    memberBalances.forEach((person, balance) {
      if (balance < 0) {
        debtors[person] = balance.abs();
      } else if (balance > 0) {
        creditors[person] = balance;
      }
    });

    final transactions = <SimpleTransaction>[];

    // Use a greedy approach to match debtors with creditors.
    for (var debtorEntry in debtors.entries) {
      var debtor = debtorEntry.key;
      var debt = debtorEntry.value;

      while (debt > 0.01) { // Use a small epsilon for double comparison
        // Find a creditor to pay.
        if (creditors.isEmpty) break;
        var creditorEntry = creditors.entries.first;
        var creditor = creditorEntry.key;
        var credit = creditorEntry.value;

        // The amount to be paid is the smaller of the debt or the credit.
        final paymentAmount = debt < credit ? debt : credit;

        transactions.add(SimpleTransaction(
          from: debtor,
          to: creditor,
          amount: paymentAmount,
        ));

        // Update the remaining debt and credit.
        debt -= paymentAmount;
        creditors[creditor] = credit - paymentAmount;

        // If a creditor is fully paid, remove them from the list.
        if (creditors[creditor]! < 0.01) {
          creditors.remove(creditor);
        }
      }
    }
    return transactions;
  }
}