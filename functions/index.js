// BOUH Cloud Functions 

import { onRequest } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp } from "firebase-admin/app";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// HTTP endpoint called by the Spring Boot backend after it decides a notification is needed.
//
// Expected JSON body:
//   targetUserId         - UID of the user who should receive the notification
//   targetRole           - "caregiver" or "doctor" (determines which Firestore collection to query)
//   notificationType     - "doctor_canceled" or "caregiver_canceled" (determines message content)
//   appointmentStartTime - human-readable time string, e.g. "4:30 مساءً" (included in title)
export const sendCancellationNotification = onRequest(async (req, res) => {
  // Only accept POST
  if (req.method !== "POST") {
    res.status(405).json({ success: false, reason: "method_not_allowed" });
    return;
  }

  const { targetUserId, targetRole, notificationType, appointmentStartTime } = req.body;

  // Validate all required fields
  if (!targetUserId || !targetRole || !notificationType) {
    console.log("Missing required fields in request body.");
    res.status(400).json({ success: false, reason: "missing_required_fields" });
    return;
  }

  // Determine which Firestore collection holds the target user's FCM token
  let collection;
  if (targetRole === "caregiver") {
    collection = "caregivers";
  } else if (targetRole === "doctor") {
    collection = "doctors";
  } else {
    console.log("Invalid targetRole:", targetRole);
    res.status(400).json({ success: false, reason: "invalid_target_role" });
    return;
  }

  // Fetch the target user's FCM token from Firestore
  const userDoc = await db.collection(collection).doc(targetUserId).get();
  const token = userDoc.exists ? userDoc.data().fcmToken : null;

  if (!token) {
    console.log(`No FCM token found for ${targetRole} ${targetUserId}, skipping.`);
    res.status(200).json({ success: false, reason: "no_fcm_token" });
    return;
  }

  // Build notification content based on notificationType
  const timeLabel = appointmentStartTime || "";
  let title;
  let body;
  if (notificationType === "doctor_canceled") {
    // Backend sends full label e.g. "يوم الأحد 14 مايو الساعة 5:30 مساءً"
    body = timeLabel
      ? "تم إلغاء موعد " + timeLabel
      : "تم إلغاء الموعد";
    title = "تم إلغاء الموعد من قبل الطبيب.";
  } else if (notificationType === "caregiver_canceled") {
    body = timeLabel
      ? "تم إلغاء موعد اليوم الساعة " + timeLabel
      : "تم إلغاء الموعد";
    title = "تم إلغاء الموعد من قبل مقدم الرعاية.";
  } else {
    console.log("Unknown notificationType:", notificationType);
    res.status(400).json({ success: false, reason: "unknown_notification_type" });
    return;
  }

  // Send the notification
  try {
    await messaging.send({
      notification: { title, body },
      token,
    });
    console.log(`Cancellation notification sent to ${targetRole} ${targetUserId}`);
    res.status(200).json({ success: true, notified: targetRole });
  } catch (err) {
    console.error(`Error sending cancellation notification to ${targetRole} ${targetUserId}:`, err);
    res.status(500).json({ success: false, reason: "send_failed" });
  }
});

export const sendBookingNotification = onRequest(async (req, res) => {
    if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
    }

    const { targetUserId, appointmentStartTime } = req.body;

    if (!targetUserId) {
        console.log("Missing required fields in request body.");
        res.status(400).send("Missing required fields");
        return;
    }

    try {
        const userDoc = await db.collection("doctors")
            .doc(targetUserId)
            .get();

        if (!userDoc.exists) {
            return res.status(404).send("User not found");
        }

        const token = userDoc.exists ? userDoc.data().fcmToken : null;
        if (!token) {
              console.log(`No FCM token found for doctor ${targetUserId}, skipping.`);
              res.status(200).json({ success: false, reason: "no_fcm_token" });
              return;        
            }

        const timeLabel = appointmentStartTime || "";
        await messaging.send({
            token,
            notification: {
                title: "موعد جديد قريب",
                body: timeLabel ? `تم حجز موعد جديد الساعة ${timeLabel}` : "تم حجز موعد جديد",
            },
        });
      
        console.log(`Booking notification sent to doctor ${targetUserId}`);
        return res.status(200).send("Notification sent");

    } catch (error) {
        console.error("sendBookingNotification error:", error);
        return res.status(500).send("Internal error: " + error.message);
    }
});
