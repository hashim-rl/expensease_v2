import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:expensease/app/modules/groups/controllers/group_dashboard_controller.dart';
import 'package:expensease/app/routes/app_routes.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';
import 'package:expensease/app/shared/theme/text_styles.dart';

class GroupDashboardView extends GetView<GroupDashboardController> {
  const GroupDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(
            () {
          // Add a null check here to prevent crashes while group data is loading
          if (controller.group.value == null) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text("Error: Group data is missing."));
          }
          // The rest of your UI builds here
          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildBalanceCard()),
                  SliverPersistentHeader(
                    delegate: _SliverTabBarDelegate(
                      const TabBar(
                        tabs: [
                          Tab(text: 'Expenses'),
                          Tab(text: 'Balances'),
                        ],
                        labelColor: AppColors.primaryBlue,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primaryBlue,
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildExpenseList(),
                  _buildBalancesView(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.group.value != null) {
            Get.toNamed(
              Routes.ADD_EXPENSE,
              arguments: {
                'group': controller.group.value,
                'members': controller.members.toList(),
              },
            );
          }
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      title: Obx(() => Text(
        controller.group.value?.name ?? 'Group',
        style: AppTextStyles.title,
      )),
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: _buildMemberAvatars(),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Group Settings",
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            if (controller.group.value != null) {
              Get.toNamed(
                Routes.MEMBERS_PERMISSIONS,
                arguments: controller.group.value,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildMemberAvatars() {
    return Obx(() {
      final membersToShow = controller.members.take(5).toList();
      final remainingCount = controller.members.length - membersToShow.length;

      return SizedBox(
        height: 40,
        child: Stack(
          children: [
            ...List.generate(membersToShow.length, (index) {
              final member = membersToShow[index];
              return Positioned(
                left: index * 25.0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
            if (remainingCount > 0)
              Positioned(
                left: membersToShow.length * 25.0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildBalanceCard() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Obx(() {
          final balance = controller.currentUserNetBalance.value;
          final isOwed = balance > 0.01;
          final owes = balance < -0.01;
          final color = isOwed ? AppColors.green : AppColors.red;

          String title;
          if (isOwed) {
            title = "Overall, you are owed";
          } else if (owes) {
            title = "Overall, you owe";
          } else {
            title = "You are all settled up!";
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.bodyText1
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              if (isOwed || owes)
                Text(
                  currencyFormat.format(balance.abs()),
                  style:
                  AppTextStyles.headline1.copyWith(color: color, fontSize: 28),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: owes || isOwed
                      ? () {
                    if (controller.group.value != null) {
                      Get.toNamed(
                        Routes.SETTLE_UP,
                        arguments: controller.group.value,
                      );
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Settle Up'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildExpenseList() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Obx(() {
      if (controller.expenses.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'No Expenses Yet',
          subtitle: 'Tap the (+) button to add the first expense.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        itemCount: controller.expenses.length,
        itemBuilder: (context, index) {
          final expense = controller.expenses[index];
          final currentUserId = controller.currentUserId;
          final userShare = expense.splitBetween[currentUserId] ?? 0.0;
          final paidBy = controller.getMemberName(expense.paidById);

          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child:
                Icon(Icons.shopping_cart_outlined, color: AppColors.primaryBlue),
              ),
              title: Text(expense.description, style: AppTextStyles.bodyBold),
              subtitle: Text(
                  'Paid by $paidBy on ${DateFormat.MMMd().format(expense.date)}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(expense.totalAmount),
                    style: AppTextStyles.bodyBold,
                  ),
                  if (userShare > 0)
                    Text(
                      'You owe ${currencyFormat.format(userShare)}',
                      style:
                      AppTextStyles.bodyText1.copyWith(color: AppColors.red),
                    )
                ],
              ),
              onTap: () =>
                  Get.toNamed(Routes.EXPENSE_DETAILS, arguments: expense),
            ),
          );
        },
      );
    });
  }

  Widget _buildBalancesView() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Obx(() {
      final balances = controller.memberBalances.entries.toList();
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        itemCount: balances.length,
        itemBuilder: (context, index) {
          final entry = balances[index];
          final memberName = controller.getMemberName(entry.key);
          final balance = entry.value;

          final color = balance >= 0 ? AppColors.green : AppColors.red;
          final text = balance >= 0
              ? currencyFormat.format(balance)
              : currencyFormat.format(balance.abs());
          final prefix = balance >= 0 ? 'Gets back ' : 'Owes ';

          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Text(
                  memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(memberName, style: AppTextStyles.bodyBold),
              subtitle: Text(
                prefix + text,
                style: AppTextStyles.bodyText1.copyWith(color: color),
              ),
            ),
          );
        },
      );
    });
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}