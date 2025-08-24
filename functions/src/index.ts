import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
// Install Twilio: npm install twilio
import * as twilio from "twilio";

admin.initializeApp();
const db = admin.firestore();

// Initialize Twilio client from secure Firebase config
const client = twilio(
  functions.config().twilio.sid,
  functions.config().twilio.token
);

// Scheduled function to create recurring expenses and send WhatsApp reminders
export const createRecurringExpenses = functions.pubsub
  .schedule("every day 01:00")
  .onRun(async () => {
    const today = new Date();

    // Query all active recurring expense templates due today or earlier
    const query = db.collectionGroup("recurringExpenses")
      .where("nextDueDate", "<=", today);

    const dueExpenses = await query.get();

    const batch = db.batch();
    const reminderPromises: Promise<any>[] = [];

    dueExpenses.forEach((doc) => {
      const recurringData = doc.data();

      // 1. Create the new expense document
      const newExpenseRef = db.collection("groups")
        .doc(recurringData.groupId)
        .collection("expenses")
        .doc();

      batch.set(newExpenseRef, {
        description: recurringData.description,
        totalAmount: recurringData.totalAmount,
        paidBy: recurringData.paidBy,
        split: recurringData.split,
        date: admin.firestore.Timestamp.now(),
        // add more expense fields if needed
      });

      // 2. Calculate the next due date
      const nextDueDate = new Date(recurringData.nextDueDate.toDate());
      if (recurringData.frequency === "Monthly") {
        nextDueDate.setMonth(nextDueDate.getMonth() + 1);
      } else if (recurringData.frequency === "Weekly") {
        nextDueDate.setDate(nextDueDate.getDate() + 7);
      }

      // 3. Update the template with the new nextDueDate
      batch.update(doc.ref, {
        nextDueDate: admin.firestore.Timestamp.fromDate(nextDueDate),
      });

      // 4. Send WhatsApp reminder if a phone number is set
      if (recurringData.whatsappNumber) {
        const to = `whatsapp:${recurringData.whatsappNumber}`; // e.g., whatsapp:+923001234567
        const message = `Reminder: Your recurring expense "${recurringData.description}" of amount ${recurringData.totalAmount} has been created.`;

        reminderPromises.push(
          client.messages.create({
            from: functions.config().twilio.whatsapp_from,
            to,
            body: message,
          }).then(() => {
            functions.logger.log(`WhatsApp reminder sent to ${to}`);
          }).catch((err) => {
            functions.logger.error(`Failed to send WhatsApp to ${to}`, err);
          })
        );
      }
    });

    // Commit all Firestore changes
    await batch.commit();

    // Wait for all WhatsApp messages to be sent
    await Promise.all(reminderPromises);

    functions.logger.log(`Created ${dueExpenses.size} recurring expenses and sent reminders where applicable.`);
    return null;
  });
