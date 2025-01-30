import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubWiseAttendancePage extends StatefulWidget {
  const SubWiseAttendancePage({super.key});

  @override
  State<SubWiseAttendancePage> createState() => _SubWiseAttendancePageState();
}

class _SubWiseAttendancePageState extends State<SubWiseAttendancePage> {
  String? erpNo;

  @override
  void initState() {
    super.initState();
    _loadErpNo();
  }

  Future<void> _loadErpNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      erpNo = prefs.getString('erpNo');
    });
  }

  Stream<Map<String, double>> fetchAttendancePercentagesStream() {
    final subjectCollection = FirebaseFirestore.instance
        .collection('studentAttendance')
        .doc(erpNo)
        .collection('subjects');

    return subjectCollection.snapshots().map((querySnapshot) {
      Map<String, double> attendanceData = {};

      for (var doc in querySnapshot.docs) {
        double percentage = (doc.data()['attendancePercentage'] ?? 0) / 100;
        attendanceData[doc.id] = percentage;
      }

      return attendanceData;
    });
  }

  double calculateTotalAttendancePercentage(Map<String, double> attendanceData) {
    if (attendanceData.isEmpty) return 0.0;
    double total = attendanceData.values.reduce((a, b) => a + b);
    return total / attendanceData.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(title: const Text('Subject Wise Attendance')),
      body: erpNo == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<String, double>>(
              stream: fetchAttendancePercentagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading attendance data'));
                }

                final attendanceData = snapshot.data!;
                double totalPercentage =
                    calculateTotalAttendancePercentage(attendanceData);

                return GridView.count(
                  crossAxisCount: 2,
                  children: [
                    ...attendanceData.entries.map((entry) {
                      String subject = entry.key;
                      double percent = entry.value;

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              CircularPercentIndicator(
                                radius: 55,
                                lineWidth: 8,
                                progressColor: const Color(0xff04486fd),
                                backgroundColor:
                                    const Color.fromARGB(238, 175, 193, 225),
                                percent: percent,
                                circularStrokeCap: CircularStrokeCap.round,
                                center: Text(
                                    '${(percent * 100).toStringAsFixed(0)}%'),
                              ),
                              Text(
                                subject,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Add the total attendance indicator at the end
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            CircularPercentIndicator(
                              radius: 55,
                              lineWidth: 8,
                              progressColor: const Color(0xff04486fd),
                              backgroundColor:
                                  const Color.fromARGB(238, 175, 193, 225),
                              percent: totalPercentage,
                              circularStrokeCap: CircularStrokeCap.round,
                              center: Text(
                                  '${(totalPercentage * 100).toStringAsFixed(1)}%'),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
