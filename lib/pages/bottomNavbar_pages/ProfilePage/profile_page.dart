import 'package:attendsure/pages/screens/teacherAndStudent.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sub_wise_attendance.dart';

// Dummy pages for each functionality (replace these with actual pages)
class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Personal Details')),
      body: Center(child: Text('Personal Details')),
    );
  }
}

class AcademicDetailsPage extends StatelessWidget {
  const AcademicDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Academic Details')),
      body: Center(child: Text('Academic Details')),
    );
  }
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results')),
      body: Center(child: Text('Results')),
    );
  }
}

class FeeDetailsPage extends StatelessWidget {
  const FeeDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fee Details')),
      body: Center(child: Text('Fee Details')),
    );
  }
}

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logout')),
      body: Center(child: Text('Logged Out')),
    );
  }
}

// LoginPage class (the page where the user will be redirected after logout)
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(child: Text('Please log in')),
    );
  }
}

class MyList extends StatelessWidget {
  final List<Map<String, dynamic>> datalist = [
    {
      'icon': Icons.person,
      'title': 'Personal Details',
      'page': PersonalDetailsPage()
    },
    {
      'icon': Icons.school,
      'title': 'Academic Details',
      'page': AcademicDetailsPage()
    },
    {
      'icon': Icons.calendar_month,
      'title': 'Subject Wise Attendance',
      'page': SubWiseAttendancePage()
    },
    {'icon': Icons.bar_chart, 'title': 'Results', 'page': ResultsPage()},
    {'icon': Icons.money, 'title': 'Fee Details', 'page': FeeDetailsPage()},
    {
      'icon': Icons.logout,
      'title': 'Logout',
      'page': null
    }, // No page for Logout
  ];

   MyList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: datalist.map((data) {
        return Card(
          child: ListTile(
            leading: Icon(data['icon']),
            title: Text(data['title']),
            trailing: Icon(Icons.arrow_right_outlined),
            onTap: () async {
              if (data['title'] == 'Logout') {
                // Perform Firebase logout
                await FirebaseAuth.instance.signOut();

                // Navigate to login page after logout
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TeacherandstudentPage()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              } else {
                // Navigate to respective page when tapped (except Logout)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => data['page']),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class MyInformationPage extends StatelessWidget {
  const MyInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyList(),
    );
  }
}
