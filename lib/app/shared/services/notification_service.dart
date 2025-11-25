import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

// --- UPDATED SERVICE: CLIENT-SIDE WHATSAPP INTEGRATION ---
// This version costs $0 and works without complex server setup.
class NotificationService {

  /// Opens WhatsApp with a pre-filled message.
  /// This acts as a "Manual Trigger" that gives the user control.
  Future<void> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    // 1. Clean the phone number (remove spaces, dashes)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+|-'), '');

    // 2. Encode the message for URL safety
    String encodedMessage = Uri.encodeComponent(message);

    // 3. Construct the deep links
    // Primary: Try to open the installed app
    final Uri appUrl = Uri.parse("whatsapp://send?phone=$cleanNumber&text=$encodedMessage");
    // Fallback: Open via web browser (universal)
    final Uri webUrl = Uri.parse("https://wa.me/$cleanNumber?text=$encodedMessage");

    try {
      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl);
      } else {
        // Fallback to web if app isn't installed
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("!!! NOTIFICATION SERVICE ERROR: $e");
      Get.snackbar(
        'Could not open WhatsApp',
        'Please ensure WhatsApp is installed or the number is correct.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}