import 'dart:async';
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/view_attendance.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qrDisplay_page.dart';
// Import the view attendance page

class TrattendanceWithQRPage extends StatefulWidget {
  const TrattendanceWithQRPage({super.key});
  @override
  State<TrattendanceWithQRPage> createState() => _TrattendanceWithQRPageState();
}

class _TrattendanceWithQRPageState extends State<TrattendanceWithQRPage> {
  String? erpNo;
  String? valueChoose;
  String? startTime;
  String? endTime;
  int otp = 0;
  String? teacherId;
  Position? teacherPosition;
  DateTime? generatedTime;
  String? teacherName;
  String collectionName = 'attendanceRecords';
  List? presentStudents;

  List<String> subjects = [
    'AI',
    'Web Computing (WC)',
    'Computer Network (CN)',
    'DWM',
    'SAIDS',
    'IOT'
  ];

  List<String> timeOptions = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '01:00',
    '01:30',
    '02:00',
    '02:30',
    '03:00',
    '03:30',
    '04:00',
    '04:30',
    '05:00'
  ];

  Future<void> getTeacherIdFromERP(String erpNo) async {
    try {
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('teacher')
          .doc(erpNo)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          teacherId = teacherDoc['teacherId'];
          teacherName = teacherDoc['name'];
        });
        print("Teacher ID: $teacherId");
      } else {
        print("No teacher found with the provided ERP No.");
      }
    } catch (e) {
      print("Error fetching Teacher ID: $e");
    }
  }

  void generateOtp() async {
    await checkLocationPermission();
    if (valueChoose == null) {
      showSnackBar('Select a Subject First');
    } else {
      if (teacherPosition != null) {
        Random random = Random();
        int min = 100000;
        int max = 1000000;
        setState(() {
          otp = min + random.nextInt((max + 1) - min);
          generatedTime = DateTime.now();
        });
        // Reset the attendance record when OTP is generated.
        storeAttendanceData();
        print('Generated OTP: $otp');
        print('Generated Time: $generatedTime');
      } else {
        print("Location services are required to generate OTP.");
      }
    }
  }

  Future<void> _loadErpNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      erpNo = prefs.getString('erpNo');
    });

    if (erpNo != null) {
      print("Loaded ERP No: $erpNo");
      getTeacherIdFromERP(erpNo!);
    } else {
      print("Error: ERP No is null or not saved.");
    }
  }

  // Modified storeAttendanceData() that resets the attendance record:
  void storeAttendanceData() async {
    if (valueChoose != null &&
        startTime != null &&
        endTime != null &&
        teacherPosition != null) {
      DocumentReference subjectDoc = FirebaseFirestore.instance
          .collection(collectionName)
          .doc(valueChoose);
      // Prepare QR data string to store in Firestore
      String qrData = "$valueChoose|$otp|$startTime|$endTime";
      
      // Fetch all students from the "students" collection to reset attendance.
      QuerySnapshot studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();
      List<String> allStudentNames = studentsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] as String? ?? '';
      }).where((name) => name.isNotEmpty).toList();

      // Reset (or create) the attendance document with:
      // - absentstd: all student names
      // - presentStudents: empty list
      // - update other fields (otp, timings, teacher details, and QR data)
      await subjectDoc.set({
        'otp': otp,
        'subject': valueChoose,
        'startTime': startTime,
        'endTime': endTime,
        'generatedTime': generatedTime,
        'teacherLocation': GeoPoint(teacherPosition!.latitude, teacherPosition!.longitude),
        'TotalLectures': FieldValue.increment(1),
        'teacherName': teacherName,
        'presentStudents': [],
        'absentstd': allStudentNames,
        'qrData': qrData,
      }, SetOptions(merge: true));

      print("Attendance record initialized for subject: $valueChoose");
    } else {
      print('Please select subject, time, and ensure location is available.');
    }
  }

  Future<void> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      teacherPosition = await Geolocator.getLastKnownPosition();
      teacherPosition ??= await Geolocator.getCurrentPosition(locationSettings: locationSettings);

      StreamSubscription<Position> positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {
        if (mounted) {
          setState(() {
            teacherPosition = position;
          });
          print("Updated Position: ${position.latitude}, ${position.longitude}");
        }
      });
      @override
      void dispose() {
        positionStream.cancel();
        super.dispose();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text('This app requires location access to generate the OTP. Please allow access.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Permanently Denied'),
          content: Text('You have permanently denied location access. Please enable it from the app settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('Go to Settings'),
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _loadErpNo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8E8E8),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFE8E8E8),
              Color(0xFF71C8F9),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Subject:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text('Subject:'),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                value: valueChoose,
                onChanged: (String? newValue) {
                  setState(() {
                    valueChoose = newValue;
                  });
                },
                items: subjects.map((String currentSubj) {
                  return DropdownMenuItem<String>(
                    value: currentSubj,
                    child: Text(currentSubj),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text("Select Lecture Time:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: const Text('Start Time'),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      iconSize: 30,
                      value: startTime,
                      onChanged: (String? newValue) {
                        setState(() {
                          startTime = newValue;
                        });
                      },
                      items: timeOptions.map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      hint: const Text('End Time'),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      iconSize: 30,
                      value: endTime,
                      onChanged: (String? newValue) {
                        setState(() {
                          endTime = newValue;
                        });
                      },
                      items: timeOptions.map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Button to generate OTP and store data (including QR data)
                  ElevatedButton(
                    onPressed: () {
                      generateOtp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0486FD),
                    ),
                    child: Text(
                      "Generate OTP",
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Button to navigate to the QR display page
                  ElevatedButton(
                    onPressed: () {
                      if (valueChoose == null || startTime == null || endTime == null) {
                        showSnackBar('Please select a subject and lecture timings');
                        return;
                      }
                      if (otp == 0) {
                        showSnackBar('Please generate OTP first');
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrDisplayPage(
                            otp: otp,
                            subject: valueChoose!,
                            startTime: startTime!,
                            endTime: endTime!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0486FD),
                    ),
                    child: Text(
                      "Generate QR",
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display OTP Container
                  Container(
                    height: 100,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 35, horizontal: 20),
                    child: Text("OTP is $otp",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  // NEW: View Attendance button below OTP display
                  ElevatedButton(
                    onPressed: () {
                      if (valueChoose == null) {
                        showSnackBar("Please select a subject");
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewAttendance(subject: valueChoose!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0486FD),
                    ),
                    child: Text(
                      "View Attendance",
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// -------------------------------------------------------

