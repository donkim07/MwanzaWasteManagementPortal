/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore} = require("firebase-admin/firestore");

// Initialize Firebase Admin
initializeApp();

// Get Firestore and Messaging instances
const firestore = getFirestore();
const messaging = getMessaging();

exports.sendFCMNotification =
onDocumentCreated("/wasteReports/{reportId}", async (event) => {
  // Change this line to avoid using optional chaining
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const reportData = snapshot.data();
  const reportId = event.params.reportId;

  if (!reportData) {
    console.log("No report data found");
    return;
  }

  try {
    // Get all admin users
    const adminSnapshot = await firestore
        .collection("users")
        .where("role", "==", "admin")
        .get();

    const notifications = adminSnapshot.docs.map(async (adminDoc) => {
      const token = adminDoc.data().fcmToken;
      if (!token) {
        console.log(`No FCM token found for admin ${adminDoc.id}`);
        return;
      }

      const message = {
        token: token,
        notification: {
          title: "New Waste Report",
          body: `Report from ${reportData.district} - ${reportData.ward}`,
        },
        data: {
          reportId: reportId,
          screen: "WasteReportsMap",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          // type: "waste_report",
          imageUrl: reportData.imageUrl || "",
        },
        android: {
          priority: "high",
          notification: {
            imageUrl: reportData.imageUrl || "",
            channelId: "waste_reports_channel",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
            // clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              "countAvailable": true,
              // "mutable-content": 1,
              "sound": "default",
              "priority": "high",
              "badge": 1,
              // "category": "waste_report",
            },
            screen: "WasteReportsMap",
            reportId: reportId,
          },
          fcm_options: {
            image: reportData.imageUrl || "",
          },
        },
      };

      try {
        const response = await messaging.send(message);
        console.log("Successfully sent message:", response);
        return response;
      } catch (error) {
        console.error("Error sending message:", error);
        return null;
      }
    });

    const results = await Promise.all(notifications);
    const successfulSends =
    results.filter(Boolean).length;
    console.log(`Successfully sent 
      ${successfulSends} notifications 
      out of ${notifications.length} attempts`);
  } catch (error) {
    console.error("Error sending notifications:", error);
    throw new Error("Failed to process notifications");
  }
});
