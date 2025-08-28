import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';
import '../controllers/specialized_modes_controller.dart';

class CouplesModeSetupView extends GetView<SpecializedModesController> {
  const CouplesModeSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Couples Mode', style: AppTextStyles.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.partnerA.value == null || controller.partnerB.value == null) {
          return const Center(
            child: Text('Error: Could not load partner details.'),
          );
        }
        return _buildContent();
      }),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proportional Splitting', style: AppTextStyles.headline2),
                const SizedBox(height: 8),
                Text(
                  'Adjust the sliders to match each partner\'s monthly income. This will set the default split ratio for shared expenses.',
                  style: AppTextStyles.bodyText1,
                ),
                const SizedBox(height: 24),
                _buildIncomeSlider(
                  partnerName: controller.partnerA.value!.fullName,
                  incomeValue: controller.partnerAIncome.value,
                  onChanged: controller.updatePartnerAIncome,
                  ratio: controller.partnerARatio.value,
                ),
                const SizedBox(height: 16),
                _buildIncomeSlider(
                  partnerName: controller.partnerB.value!.fullName,
                  incomeValue: controller.partnerBIncome.value,
                  onChanged: controller.updatePartnerBIncome,
                  ratio: controller.partnerBRatio.value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCard(
            child: _buildSavingsGoal(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: controller.saveCoupleModeSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Save Settings', style: AppTextStyles.button),
          )
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }

  Widget _buildIncomeSlider({
    required String partnerName,
    required double incomeValue,
    required Function(double) onChanged,
    required double ratio,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(partnerName, style: AppTextStyles.bodyBold),
            Text(
              '${(ratio * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryBlue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(currencyFormat.format(incomeValue), style: AppTextStyles.bodyText1),
        Slider(
          value: incomeValue,
          min: 0,
          max: 20000,
          divisions: 200,
          label: currencyFormat.format(incomeValue),
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildSavingsGoal() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Joint Savings Goal', style: AppTextStyles.headline2),
        const SizedBox(height: 8),
        Text(
          'Set a monthly goal for combined savings.',
          style: AppTextStyles.bodyText1,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Monthly Goal', style: AppTextStyles.bodyBold),
            Text(
              currencyFormat.format(controller.monthlySavingsGoal.value),
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.green),
            ),
          ],
        ),
        Slider(
          value: controller.monthlySavingsGoal.value,
          min: 0,
          max: 5000,
          divisions: 100,
          label: currencyFormat.format(controller.monthlySavingsGoal.value),
          onChanged: controller.updateMonthlySavingsGoal,
          activeColor: AppColors.green,
        ),
        const SizedBox(height: 16),
        Text(
          'Progress: ${currencyFormat.format(controller.currentSavings.value)} / ${currencyFormat.format(controller.monthlySavingsGoal.value)}',
          style: AppTextStyles.bodyText1,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (controller.monthlySavingsGoal.value > 0)
              ? controller.currentSavings.value / controller.monthlySavingsGoal.value
              : 0,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ));
  }
}