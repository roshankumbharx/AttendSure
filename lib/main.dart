import 'package:attendsure/firebase_services/std_details.dart';
import 'package:attendsure/pages/bottomNavbar_pages/Homepage/std_home_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/Homepage/tr_home_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/attendance_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/qrDisplay_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/qrScanner_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/stdAttendanaceWithqr_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/stdAttendance_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/trAttendanceWithqr_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/trAttendance_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/view_attendance.dart';
import 'package:attendsure/pages/bottomNavbar_pages/ProfilePage/profile_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/notifications_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/settings_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/timetable_page.dart';
import 'package:attendsure/pages/screens/std_erpLogin.dart';
import 'package:attendsure/pages/screens/home_page.dart';
import 'package:attendsure/pages/screens/teacherAndStudent.dart';
import 'package:attendsure/pages/screens/tr_erpLogin_page.dart';
import 'package:attendsure/utils/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/trAndstd',
      routes: {
        Myroutes.attendanceRoute: (context) => AttendancePage(),
        Myroutes.notificationsRoute: (context) => NotificationsPage(),
        Myroutes.timetableRoute: (context) => TimetablePage(),
        Myroutes.myinformationRoute: (context) => MyInformationPage(),
        Myroutes.settingsRoute: (context) => SettingsPage(),
        Myroutes.erpLoginRoute: (context) => ErpLogin(),
        Myroutes.trAndstdroute: (context) => TeacherandstudentPage(),
        Myroutes.trErpLoginRoute: (context) => TrErploginPage(),
        Myroutes.trAttendanceRoute: (context) => TrattendancePage(),
        Myroutes.stdAttendanceRoute: (context) => StdattendancePage(),
        Myroutes.viewAttendanceRoute: (context) => ViewAttendance(subject: '',),
        Myroutes.trHomePageRoute: (context) => TrHomePage(),
        Myroutes.stdHomePageRoute: (context) => StdHomePage(),
        Myroutes.trAttendanceWithqrRoute: (context) => TrattendanceWithQRPage(),
        Myroutes.stdAttendanceWithqrRoute: (context) => StdattendanceWithQRPage(),
        Myroutes.QRscannerRoute: (context) => QRScanPage(),
        // Remove direct mapping for QrDisplayPage from routes
      },
      onGenerateRoute: (settings) {
        // Handle QrDisplayPage route by extracting arguments
        if (settings.name == Myroutes.QRDisplayRoute) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => QrDisplayPage(
              otp: args['otp'] as int,
              subject: args['subject'] as String,
              startTime: args['startTime'] as String,
              endTime: args['endTime'] as String,
            ),
          );
        }
        // Handle other dynamic routes if needed.
        if (settings.name == Myroutes.stdDetailsRoute) {
          return MaterialPageRoute(
            builder: (context) => StudentDetails(), // No erpNo needed here
          );
        }
        if (settings.name == Myroutes.homeRoute) {
          final arguments = settings.arguments as Map<String, String>;
          final loginType = arguments['loginType']!;
          return MaterialPageRoute(
            builder: (context) => HomePage(loginType: loginType),
          );
        }
        if (settings.name == Myroutes.trDetailsRoute) {
          final arguments = settings.arguments as Map<String, String>;
          final loginType = arguments['loginType']!;
          return MaterialPageRoute(
            builder: (context) => HomePage(loginType: loginType),
          );
        }
        return null;
      },
    );
  }
}
