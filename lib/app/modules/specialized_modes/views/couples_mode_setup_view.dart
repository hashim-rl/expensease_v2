import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/specialized_modes_controller.dart';

// A one-time onboarding process to establish the proportional split ratio [cite: 288]
class CouplesModeSetupView extends GetView<SpecializedModesController> {
  const CouplesModeSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Couples Mode')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enter each partner\'s income to automatically split shared expenses proportionally.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            // The screen prompts Partner A and Partner B to enter their respective incomes [cite: 291]
            TextField(
              controller: controller.partnerAIncomeController,
              decoration: const InputDecoration(labelText: 'Partner A Monthly Income'),
              keyboardType: TextInputType.number,
              onChanged: (_) => controller.calculateIncomeRatio(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.partnerBIncomeController,
              decoration: const InputDecoration(labelText: 'Partner B Monthly Income'),
              keyboardType: TextInputType.number,
              onChanged: (_) => controller.calculateIncomeRatio(),
            ),
            const SizedBox(height: 32),
            Text('Calculated Split Ratio', style: Theme.of(context).textTheme.titleLarge),
            // The app instantly calculates the income ratio and displays it clearly [cite: 293]
            Obx(() => Text(
              controller.incomeRatio.value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
            )),
            const Spacer(),
            ElevatedButton(
              onPressed: controller.saveCoupleModeSettings,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('Confirm & Save Ratio'),
            )
          ],
        ),
      ),
    );
  }
}