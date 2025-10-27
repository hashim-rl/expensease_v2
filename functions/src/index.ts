import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
// Ensure Twilio is installed: npm install twilio
import * as twilio from "twilio";

admin.initializeApp();
const db = admin.firestore();

// --- Configuration ---
// Ensure Twilio credentials are set in Firebase Functions config:
// firebase functions:config:set twilio.sid="ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
// firebase functions:config:set twilio.token="your_auth_token"
// firebase functions:config:set twilio.whatsapp_from="whatsapp:+14155238886" (Your Twilio WhatsApp number)
const twilioConfig = functions.config().twilio;
const TWILIO_SID = twilioConfig?.sid;
const TWILIO_TOKEN = twilioConfig?.token;
const TWILIO_WHATSAPP_FROM = twilioConfig?.whatsapp_from;

let client: twilio.Twilio | null = null;
if (TWILIO_SID && TWILIO_TOKEN && TWILIO_WHATSAPP_FROM) {
  try {
    client = twilio(TWILIO_SID, TWILIO_TOKEN);
    functions.logger.info("Twilio client initialized successfully.");
  } catch (error) {
    functions.logger.error("Failed to initialize Twilio client:", error);
  }
} else {
  functions.logger.warn(
    "Twilio config (sid, token, whatsapp_from) not fully set. WhatsApp reminders will be disabled."
  );
}

// Helper function to calculate the next due date
function calculateNextDueDate(
  currentDueDate: Date,
  frequency: string
): admin.firestore.Timestamp {
  const nextDate = new Date(currentDueDate);
  switch (frequency.toLowerCase()) {
    case "monthly":
      nextDate.setMonth(nextDate.getMonth() + 1);
      break;
    case "weekly":
      nextDate.setDate(nextDate.getDate() + 7);
      break;
    case "quarterly":
      nextDate.setMonth(nextDate.getMonth() + 3);
      break;
    case "yearly":
      nextDate.setFullYear(nextDate.getFullYear() + 1);
      break;
    default:
      // Fallback: If frequency is unknown, schedule for ~100 years later to stop it
      functions.logger.warn(`Unknown frequency "${frequency}", disabling future runs.`);
      nextDate.setFullYear(nextDate.getFullYear() + 100);
      break;
  }
  return admin.firestore.Timestamp.fromDate(nextDate);
}

// Scheduled function runs daily at 1:00 AM (server time, likely UTC)
export const createRecurringExpenses = functions.pubsub
  .schedule("every day 01:00")
  // .timeZone("Asia/Karachi") // Optional: Specify timezone if needed
  .onRun(async (context) => {
    // Use Firestore Timestamp for robust querying across timezones
    const now = admin.firestore.Timestamp.now();
    functions.logger.info(`Running createRecurringExpenses at ${now.toDate().toISOString()}`);

    // Query all recurring expense templates due on or before "now"
    const query = db
      .collectionGroup("recurringExpenses")
      .where("nextDueDate", "<=", now);

    let dueExpensesSnapshot: admin.firestore.QuerySnapshot;
    try {
      dueExpensesSnapshot = await query.get();
      functions.logger.info(`Found ${dueExpensesSnapshot.size} recurring expense templates due.`);
    } catch (error) {
      functions.logger.error("Error querying recurring expenses:", error);
      return null; // Exit if query fails
    }

    if (dueExpensesSnapshot.empty) {
      functions.logger.info("No recurring expenses due today.");
      return null;
    }

    const batch = db.batch();
    const reminderPromises: Promise<any>[] = [];
    let expensesCreatedCount = 0;

    dueExpensesSnapshot.forEach((doc) => {
      try {
        const recurringData = doc.data();
        const templateId = doc.id;
        const groupId = recurringData.groupId;

        // Basic validation
        if (!groupId || !recurringData.description || !recurringData.totalAmount || !recurringData.paidBy || !recurringData.split || !recurringData.frequency || !recurringData.nextDueDate) {
            functions.logger.error(`Skipping invalid template ${templateId} in group ${groupId || 'UNKNOWN'}: Missing essential data.`, recurringData);
            return; // Skip this template
        }

        functions.logger.log(`Processing template ${templateId} for group ${groupId}`);

        // 1. Prepare the new expense document data
        const newExpenseRef = db
          .collection("groups")
          .doc(groupId)
          .collection("expenses")
          .doc(); // Auto-generate ID

        const newExpenseData = {
          description: recurringData.description,
          totalAmount: recurringData.totalAmount,
          paidById: recurringData.paidBy,
          splitBetween: recurringData.split,
          date: now, // Use current timestamp for the expense date
          category: recurringData.category || "Bill", // Use template category or default
          createdAt: now,
          // Optional fields - include if they exist in the template
          ...(recurringData.notes && { notes: recurringData.notes }),
          ...(recurringData.receiptUrl && { receiptUrl: recurringData.receiptUrl }),
          recurringSourceId: templateId, // Link back to the template
        };

        batch.set(newExpenseRef, newExpenseData);
        functions.logger.info(` -> Scheduled creation for new expense ${newExpenseRef.id}`);


        // 2. Calculate the next due date based on frequency
        const nextDueDateTimestamp = calculateNextDueDate(
            recurringData.nextDueDate.toDate(),
            recurringData.frequency
        );
        functions.logger.info(` -> Calculated next due date: ${nextDueDateTimestamp.toDate().toISOString()}`);


        // 3. Update the template with the new nextDueDate
        batch.update(doc.ref, {
          nextDueDate: nextDueDateTimestamp,
        });
        functions.logger.info(` -> Scheduled update for template ${templateId}`);

        expensesCreatedCount++;

        // 4. Send WhatsApp reminder if configured and client is available
        if (client && recurringData.whatsappNumber && TWILIO_WHATSAPP_FROM) {
          const to = `whatsapp:${recurringData.whatsappNumber.trim()}`;
          // Format amount nicely (optional)
          const formattedAmount = recurringData.totalAmount.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          });
          const message = `Expensease Reminder: Your recurring expense "${recurringData.description}" for ${formattedAmount} has been automatically added to your group.`;

          functions.logger.log(` -> Queueing WhatsApp reminder to ${to}`);
          reminderPromises.push(
            client.messages
              .create({
                from: TWILIO_WHATSAPP_FROM,
                to: to,
                body: message,
              })
              .then((msg) => {
                functions.logger.info(`WhatsApp reminder sent successfully to ${to}, SID: ${msg.sid}`);
              })
              .catch((err) => {
                // Log Twilio-specific errors if available
                const errorMessage = err.message || err.toString();
                const errorCode = err.code || 'N/A';
                functions.logger.error(`Failed to send WhatsApp to ${to}. Code: ${errorCode}, Message: ${errorMessage}`);
              })
          );
        } else if (recurringData.whatsappNumber && !client) {
            functions.logger.warn(` -> Cannot send WhatsApp reminder for template ${templateId}: Twilio client not initialized (check config).`);
        }

      } catch (error) {
          functions.logger.error(`Error processing template ${doc.id}:`, error);
          // Continue processing other templates
      }
    });

    // Commit all Firestore writes
    try {
      await batch.commit();
      functions.logger.info(`Successfully committed Firestore batch for ${expensesCreatedCount} expenses.`);
    } catch (error) {
      functions.logger.error("Error committing Firestore batch:", error);
      // Even if batch fails, try sending any queued reminders
    }

    // Wait for all WhatsApp messages attempts to complete
    try {
        if (reminderPromises.length > 0) {
            await Promise.all(reminderPromises);
            functions.logger.info(`Completed processing ${reminderPromises.length} WhatsApp reminder attempts.`);
        }
    } catch (error) {
        functions.logger.error("Error occurred during Promise.all for WhatsApp reminders:", error);
    }


    functions.logger.info(`Function execution finished. Processed ${dueExpensesSnapshot.size} templates, created ${expensesCreatedCount} expenses.`);
    return null;
  });