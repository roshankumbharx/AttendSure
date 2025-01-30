import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAttendance extends StatefulWidget {
  const ViewAttendance({super.key});

  @override
  State<ViewAttendance> createState() => _ViewAttendanceState();
}

class _ViewAttendanceState extends State<ViewAttendance> {
  late final String data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    data = ModalRoute.of(context)!.settings.arguments as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendanceRecords')
            .doc(data)
            .snapshots(), // Listen for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Loading indicator
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No data found')); // Handle no data
          }

          // Extract data from the document snapshot
          var docData = snapshot.data!.data() as Map<String, dynamic>;
          var presentStudents = docData['presentStudents'] as List<dynamic>?;

          if (presentStudents == null || presentStudents.isEmpty) {
            return Center(child: Text('No present students yet'));
          }

          // Display the list of students
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Present Students:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  ...presentStudents.map((student) {
                    return Text(
                      student.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
