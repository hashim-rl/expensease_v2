import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/data/models/member_model.dart';
import 'package:expensease/app/modules/groups/controllers/members_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expensease/app/shared/theme/app_colors.dart';

class MembersPermissionsView extends GetView<MembersController> {
  const MembersPermissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color from your design
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Group Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // The "Admin" chip from the design
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Obx(() => Chip(
              label: Text(
                controller.currentUserRole.value, // Dynamically show user's role
                style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            )),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // The main column now holds our three styled cards
        child: Column(
          children: [
            _buildEditNameCard(),
            const SizedBox(height: 24),
            _buildManageCategoriesCard(),
            const SizedBox(height: 24),
            _buildMemberPermissionsCard(),
            const SizedBox(height: 24),
            _buildDangerZoneCard(), // Added a section for deleting the group
          ],
        ),
      ),
    );
  }

  /// Card for editing the group's name.
  Widget _buildEditNameCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit Group Name",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Obx(() => TextFormField(
              controller: controller.groupNameController,
              decoration: InputDecoration(
                hintText: controller.group.value.name,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: controller.updateGroupName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Card for managing expense categories.
  Widget _buildManageCategoriesCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Manage Bill Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Placeholder categories
            _categoryRow(Icons.receipt_long_outlined, "Rent"),
            _categoryRow(Icons.local_gas_station_outlined, "Gas"),
            _categoryRow(Icons.wifi, "Internet"),
            _categoryRow(Icons.shopping_cart_outlined, "Groceries"),
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: "Add New Category", border: InputBorder.none),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement add category logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// A single row in the category list.
  Widget _categoryRow(IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 16))),
          IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
              onPressed: () {
                // TODO: Implement delete category logic
              }),
        ],
      ),
    );
  }

  /// Card for managing member roles and permissions.
  Widget _buildMemberPermissionsCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Member Permissions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.members.length,
                itemBuilder: (context, index) {
                  final member = controller.members[index];
                  return _memberRow(member);
                },
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text("Add New Member"),
              onPressed: () {
                // TODO: Implement add member dialog
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A single row in the member list.
  Widget _memberRow(MemberModel member) {
    final bool isCurrentUser =
        member.id == FirebaseAuth.instance.currentUser?.uid;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(member.name.substring(0, 1).toUpperCase()),
      ),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(isCurrentUser ? "You" : member.role),
      trailing: Obx(() => DropdownButton<String>(
        value: member.role,
        underline: const SizedBox(),
        // Only admins can change roles, and they can't change their own role
        onChanged: (controller.currentUserRole.value == 'Admin' && !isCurrentUser)
            ? (value) {
          // TODO: Implement role change logic
        }
            : null, // Disables the dropdown
        items: const [
          DropdownMenuItem(value: "Admin", child: Text("Admin")),
          DropdownMenuItem(value: "Editor", child: Text("Editor")),
          DropdownMenuItem(value: "Viewer", child: Text("Viewer")),
        ],
      )),
    );
  }

  /// Card for dangerous actions like deleting the group.
  Widget _buildDangerZoneCard() {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
        title: Text(
          "Delete Group",
          style: TextStyle(
              color: Colors.red.shade900, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          // TODO: Implement delete group logic
        },
      ),
    );
  }
}