import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

// This class acts as a dedicated bridge to our backend notification functions.
class NotificationService {
  // This gets an instance of the Cloud Functions service.
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // This is the public method you will call from your controllers.
  Future<void> sendWhatsAppNotification({
    required String phoneNumber, // The recipient's phone number, e.g., '+15551234567'
    required String message,
  }) async {
    // This looks for the Cloud Function on the server with the exact name 'sendWhatsAppReminder'.
    final callable = _functions.httpsCallable('sendWhatsAppReminder');

    // This 'calls' the function and sends the phone number and message as data.
    // The actual sending of the WhatsApp message happens securely on the server, not in the app.
    try {
      await callable.call(<String, dynamic>{
        'to': 'whatsapp:$phoneNumber',
        'message': message,
      });
      debugPrint('WhatsApp reminder trigger successful.');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Failed to trigger reminder: ${e.code} - ${e.message}');
      // You could show a user-facing error here if needed.
    }
  }
}