import 'package:attendsure/pages/bottomNavbar_pages/Homepage/std_home_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/Homepage/tr_home_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/stdAttendanaceWithqr_page.dart';
// import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/stdAttendance_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/trAttendanceWithqr_page.dart';
// import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/trAttendance_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:attendsure/pages/bottomNavbar_pages/notifications_page.dart';
import 'package:attendsure/pages/bottomNavbar_pages/ProfilePage/profile_page.dart';
import 'package:attendsure/firebase_services/teacher_details.dart';
import 'package:attendsure/firebase_services/std_details.dart';

class HomePage extends StatefulWidget {
  final String loginType; // Add loginType here
  const HomePage({super.key, required this.loginType});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  String? erpNo;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _loadErpNo();
  }

  Future<void> _loadErpNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      erpNo = prefs.getString('erpNo');
    });
  }

  void _initializePages() {
    _pages = [
      _getHomePage(),
      _getAttendancePage(),
      _getDetailsPage(),
      NotificationsPage(),
      MyInformationPage(),
    ];
  }

  Widget _getDetailsPage() {
    if (widget.loginType == 'teacher') {
      return TeacherDetails(); // Use the ERP number here
    } else {
      return StudentDetails(); // Use the ERP number here
    }
  }

  Widget _getAttendancePage() {
    if (widget.loginType == 'teacher') {
      // return TrattendancePage(); // Use the ERP number here
      return TrattendanceWithQRPage();
    } else {
      // return StdattendancePage(); // Use the ERP number here
      return StdattendanceWithQRPage(); // Use the ERP number here
    }
  }

  Widget _getHomePage() {
    if (widget.loginType == 'teacher') {
      return TrHomePage(); // Use the ERP number here
    } else {
      return StdHomePage(); // Use the ERP number here
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (erpNo == null) {
      return Center(
          child:
              CircularProgressIndicator()); // Loading indicator while erpNo is fetched
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('AttendSure'),
        backgroundColor: Color(0xFF07A5FD),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home,
              color: Color(0xFF0486FD),
            ),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(
              CupertinoIcons.person_crop_circle_badge_checkmark,
              color: Color(0xFF0486FD),
            ),
            label: "Attendance",
          ),
          NavigationDestination(
            icon: Icon(
              Icons.badge,
              color: Color(0xFF0486FD),
            ),
            label: "ID",
          ),
          NavigationDestination(
            icon: Icon(
              CupertinoIcons.bell,
              color: Color(0xFF0486FD),
            ),
            label: "Notifications",
          ),
          NavigationDestination(
            icon: Icon(
              CupertinoIcons.profile_circled,
              color: Color(0xFF0486FD),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
