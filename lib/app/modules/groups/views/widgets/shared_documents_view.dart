import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expensease/app/modules/groups/controllers/family_features_controller.dart';
import 'package:expensease/app/shared/widgets/empty_state_widget.dart';

class SharedDocumentsView extends GetView<FamilyFeaturesController> {
  const SharedDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.documents.isEmpty && !controller.isLoading.value) {
          return const EmptyStateWidget(
            icon: Icons.folder_zip_outlined,
            title: 'No Documents',
            subtitle: 'Tap the (+) button to upload your first shared document.',
          );
        }
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.documents.length,
              itemBuilder: (context, index) {
                final doc = controller.documents[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description, size: 30),
                    title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Uploaded by ${doc.uploadedBy}'), // TODO: Get user name
                    onTap: () => controller.openDocument(doc.downloadUrl),
                  ),
                );
              },
            ),
            if (controller.isLoading.value) const Center(child: CircularProgressIndicator()),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.uploadDocument,
        child: const Icon(Icons.upload_file),
        tooltip: 'Upload Document',
      ),
    );
  }
}