
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAttendance extends StatefulWidget {
  final String subject;  // Pass the subject (or document ID) via the constructor
  const ViewAttendance({super.key, required this.subject});

  @override
  State<ViewAttendance> createState() => _ViewAttendanceState();
}

class _ViewAttendanceState extends State<ViewAttendance> {
  late final String attendanceDocId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the subject from the widget as the attendance document ID.
    attendanceDocId = widget.subject;
    _initializeAttendanceRecord();
  }

  // Initialize attendance record with all students as absent
  Future<void> _initializeAttendanceRecord() async {
    try {
      // Get all students
      QuerySnapshot studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();

      // Get list of all student IDs
      List<String> allStudentIds =
          studentsSnapshot.docs.map((doc) => doc.id).toList();

      // Reference to the attendance document
      DocumentReference attendanceDoc = FirebaseFirestore.instance
          .collection('attendanceRecords')
          .doc(attendanceDocId);

      // Update the document to set absentstd if not already set
      await attendanceDoc.set({
        'absentstd': allStudentIds,
        'presentStudents': FieldValue.arrayUnion([]),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error initializing attendance record: $e');
    }
  }

  // Fetch student details based on present and absent lists
  Future<List<Map<String, dynamic>>> _fetchStudentDetails(
      Map<String, dynamic> attendanceData) async {
    // Get list of present and absent students from attendance record
    List<dynamic> presentStudentIds = attendanceData['presentStudents'] ?? [];
    List<dynamic> absentStudentIds = attendanceData['absentstd'] ?? [];

    // Fetch details for all students in both lists
    QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where(FieldPath.documentId, whereIn: [...presentStudentIds, ...absentStudentIds])
        .get();

    // Map student details
    return studentsSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'erpNo': doc.id,
        'name': data['name'] ?? 'Unknown',
        'branch': data['branch'] ?? 'Unknown',
        'isPresent': presentStudentIds.contains(doc.id)
      };
    }).toList();
  }

  // Build Attendance Details Section
  Widget _buildAttendanceDetailsSection(Map<String, dynamic> attendanceData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Details:',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Subject: ${attendanceData['subject'] ?? 'Not Specified'}',
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          'Total Lectures: ${attendanceData['TotalLectures'] ?? 'Not Specified'}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Build Student List Section
  Widget _buildStudentListSection(
      String title,
      List<Map<String, dynamic>> students,
      Color titleColor,
      {bool isAbsentList = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          '$title (${students.length}):',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
        ),
        const SizedBox(height: 8),
        if (students.isEmpty) Text('No ${title.toLowerCase()} yet'),
        ...students.map((student) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${student['name']}',
                  style: const TextStyle(fontSize: 18),
                ),
                if (isAbsentList)
                  ElevatedButton(
                    onPressed: () => _markStudentPresent(student['erpNo']),
                    child: const Text('Mark Present'),
                  ),
              ],
            )),
      ],
    );
  }

  // Method to mark a student as present from the view page
  Future<void> _markStudentPresent(String studentId) async {
    try {
      DocumentReference attendanceDoc = FirebaseFirestore.instance
          .collection('attendanceRecords')
          .doc(attendanceDocId);
      await attendanceDoc.update({
        'presentStudents': FieldValue.arrayUnion([studentId]),
        'absentstd': FieldValue.arrayRemove([studentId])
      });
    } catch (e) {
      print('Error marking student present: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance for $attendanceDocId"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendanceRecords')
            .doc(attendanceDocId)
            .snapshots(),
        builder: (context, attendanceSnapshot) {
          if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!attendanceSnapshot.hasData || !attendanceSnapshot.data!.exists) {
            return const Center(child: Text('No attendance record found'));
          }

          Map<String, dynamic> attendanceData =
              attendanceSnapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchStudentDetails(attendanceData),
            builder: (context, studentsSnapshot) {
              if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!studentsSnapshot.hasData) {
                return const Center(child: Text('No student data found'));
              }
              final studentDetails = studentsSnapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAttendanceDetailsSection(attendanceData),
                      _buildStudentListSection(
                          'Present Students',
                          studentDetails
                              .where((student) => student['isPresent'] == true)
                              .toList(),
                          Colors.green,
                          isAbsentList: false),
                      _buildStudentListSection(
                          'Absent Students',
                          studentDetails
                              .where((student) => student['isPresent'] == false)
                              .toList(),
                          Colors.red,
                          isAbsentList: true),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


