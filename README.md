# 📚 AttendSure

**AttendSure** is a modern student attendance management application built with **Flutter** and **Firebase**, designed to automate the attendance process and provide real-time analytics.

---

## 🚀 Features

✅ **Real-Time Tracking and Reporting**  
✅ **OTP & QR Code-Based Attendance Marking**  
✅ **Attendance Analytics and Trends**  
✅ **Live Student Attendance Dashboard**  
✅ **Geo-Location Based Attendance Validation**

---


## Screenshorts
# Teacher's View :
<img src="./assets/TeacherView1.png" alt="Login Page" width="250"/>



## 🛠 Tech Stack

| Technology      | Role                          |
|----------------|-------------------------------|
| Flutter         | Frontend                       |
| Firebase        | Backend (Firestore, Auth)      |
| Geolocator      | Location Tracking              |
| Node.js         | Server-Side Logic              |


---

## 📦 Getting Started

### ✅ Prerequisites

Ensure the following tools are installed on your system:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart SDK
- Android Studio / Visual Studio Code
- A Firebase account

### 📥 Clone the Repository

```bash
git clone https://github.com/your-username/attensure.git
cd attendsure


Install Dependencies

flutter pub get

Configure Firebase

Create a project in Firebase Console.

Enable Firestore, Authentication, and Cloud Functions.

Download the google-services.json file and place it inside:


android/app/
Add necessary environment variables and Firebase configurations.

▶️ Run the App

flutter run
📂 Project Structure

attendsure/
├── lib/                   # App source code
│   ├── main.dart
│   ├── pages/             # UI
│   ├── utils/             # routes
│   ├── widgets/           # Data Models
│   ├── firebase_services/ # Business Logic & APIs
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── pubspec.yaml           # Flutter dependencies
└── README.md