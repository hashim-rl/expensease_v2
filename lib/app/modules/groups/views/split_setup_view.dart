import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/split_setup_controller.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';

class SplitSetupView extends GetView<SplitSetupController> {
  const SplitSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Proportional Splitting'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildMemberInputs(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 120), // Spacer for bottom bar
                ],
              ),
            ),
          ],
        );
      }),
      // Bottom persistent bar for saving and seeing the total
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: AppColors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Set default percentages for new expenses. This is ideal for groups that split costs based on income (e.g., 60/40).',
                style: AppTextStyles.bodyText1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Members', style: AppTextStyles.headline2),
        const SizedBox(height: 8),
        Obx(() {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.members.length,
            itemBuilder: (context, index) {
              final member = controller.members[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(member.nickname.isNotEmpty
                        ? member.nickname[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(member.nickname, style: AppTextStyles.bodyBold),
                  trailing: SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: controller.memberControllers[member.uid],
                      decoration: const InputDecoration(
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                      ),
                      textAlign: TextAlign.right,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.pie_chart_outline),
      label: const Text('Set Equal Split'),
      onPressed: controller.setEqualSplit,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTotalPercentageTracker(),
          const SizedBox(height: 16),
          Obx(() => ElevatedButton(
            onPressed: controller.isSaving.value
                ? null
                : controller.saveSplitRatios,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: controller.isSaving.value
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : const Text('Save Ratios'),
          )),
        ],
      ),
    );
  }

  Widget _buildTotalPercentageTracker() {
    return Obx(() {
      final total = controller.totalPercentage.value;
      final bool isValid = total == 100.0;
      final color = isValid ? AppColors.green : AppColors.red;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL',
              style: AppTextStyles.bodyBold.copyWith(color: color),
            ),
            Text(
              '${total.toStringAsFixed(1)}%',
              style: AppTextStyles.headline2.copyWith(color: color, fontSize: 20),
            ),
          ],
        ),
      );
    });
  }
}