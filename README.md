# 📚 AttendSure

**AttendSure** is a modern student attendance management application built with **Flutter** and **Firebase**, designed to automate the attendance process and provide real-time analytics.

---

## 🚀 Features  

- ✅ **Real-Time Tracking and Reporting** – Monitor attendance instantly with up-to-date records and detailed reports.  
- ✅ **OTP & QR Code-Based Attendance Marking** – Secure and quick attendance using one-time passwords or scannable QR codes.   
- ✅ **Live Student Attendance Dashboard** – Teachers and admins can view student presence in real time via an interactive dashboard.  
- ✅ **Geo-Location Based Attendance Validation** – A student can only mark attendance if they are within a certain range (e.g., 50m) of the teacher, and the OTP is time-bound (valid for 2 minutes).  
- ✅ **Manual Marking Option** – If a student fails to mark attendance for any reason, the teacher can manually mark them present using the *Mark Present* button.

---


# Screenshorts
## Landing Page :
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView1.png" alt="Landing Page" width="200"/>

## Teacher's View :
<p align="center">
  <img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView2.png" alt="Teacher View 1" width="200"/>
  <img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView3.png" alt="Teacher View 2" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView4.png" alt="Teacher View 3" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView5.png" alt="Teacher View 4" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView6.png" alt="Teacher View 5" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView7.png" alt="Teacher View 6" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/TeacherView8.png" alt="Teacher View 7" width="200"/>
  
</p>

## Student's View :

<p align="center">
  <img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/StudentView1.png" alt="Student View 1" width="200"/>
  <img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/StudentView2.png" alt="Student View 2" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/StudentView3.png" alt="Student View 3" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/StudentView4.png" alt="Student View 4" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/StudentView5.png" alt="Student View 5" width="200"/>
<img src="https://raw.githubusercontent.com/roshankumbharx/AttendSure/main/assets/images/StudentView6.png" alt="Student View 6" width="200"/>
  
</p>


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
git clone https://github.com/roshankumbharx/attendsure.git
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
