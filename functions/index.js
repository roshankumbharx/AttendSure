// /**
//  * Import function triggers from their respective submodules:
//  *
//  * const {onCall} = require("firebase-functions/v2/https");
//  * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
//  *
//  * See a full list of supported triggers at https://firebase.google.com/docs/functions
//  */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// // exports.helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });

// ------------------------------------------------------------------
// function for absent students

// Import necessary modules
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

admin.initializeApp();

// Retrieve Twilio credentials from environment configuration
const accountSid = functions.config().twilio.account_sid;
const authToken = functions.config().twilio.auth_token;
const fromWhatsAppNumber = functions.config().twilio.whatsapp_from; // e.g. 'whatsapp:+14155238886'

const client = new twilio(accountSid, authToken);

// HTTPS Cloud Function to fetch absent student ERP numbers and send WhatsApp notifications to parents
exports.sendAbsentNotifications = functions.https.onRequest(async (req, res) => {
  try {
    const subject = req.query.subject;
    if (!subject) {
      res.status(400).send("Subject parameter is required.");
      return;
    }
    
    // Fetch the attendance record for the given subject
    const attendanceDoc = await admin.firestore()
      .collection('attendanceRecords')
      .doc(subject)
      .get();
    
    if (!attendanceDoc.exists) {
      res.status(404).send("Attendance record not found.");
      return;
    }
    
    const attendanceData = attendanceDoc.data();
    // Assume absentstd is an array of ERP numbers.
    const absentList = attendanceData.absentstd || [];
    
    // For each absent student's ERP, fetch the student document to get the parent's number
    const notifications = absentList.map(async (erpNo) => {
      const studentDoc = await admin.firestore()
        .collection('students')
        .doc(erpNo)
        .get();
      if (studentDoc.exists) {
        const studentData = studentDoc.data();
        const parentNumber = studentData.parentNumber; // e.g., "+919876543210"
        const studentName = studentData.name || erpNo;
        if (parentNumber) {
          // Send a WhatsApp message using Twilio's API
          return client.messages.create({
            body: `Dear Parent, your child ${studentName} is absent today.`,
            from: fromWhatsAppNumber,
            to: `whatsapp:${parentNumber}`
          });
        } else {
          console.log(`No parent number for student ERP: ${erpNo}`);
        }
      } else {
        console.log(`Student document for ERP ${erpNo} not found.`);
      }
      return null;
    });
    
    await Promise.all(notifications);
    res.status(200).send("Notifications sent successfully.");
  } catch (error) {
    console.error("Error sending notifications:", error);
    res.status(500).send("Error sending notifications.");
  }
});
