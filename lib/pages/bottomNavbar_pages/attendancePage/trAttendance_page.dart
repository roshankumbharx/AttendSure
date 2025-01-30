import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrattendancePage extends StatefulWidget {
  const TrattendancePage({super.key});
  @override
  State<TrattendancePage> createState() => _TrattendancePageState();
}

class _TrattendancePageState extends State<TrattendancePage> {
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

  // Function to store attendance data in Firestore
  void storeAttendanceData() async {
    if (valueChoose != null &&
        startTime != null &&
        endTime != null &&
        teacherPosition != null) {
      // Reference to the document for the selected subject in the 'attendance' collection
      DocumentReference subjectDoc = FirebaseFirestore.instance
          .collection(collectionName) // 'attendance' collection
          .doc(valueChoose); // Document for the selected subject

      // Fetch the document to check if it exists
      DocumentSnapshot docSnapshot = await subjectDoc.get();

      if (docSnapshot.exists) {
        // Document exists, increment the lecture count
        await subjectDoc.update({
          'TotalLectures': FieldValue.increment(1),
          'startTime': startTime,
          'endTime': endTime,
          'generatedTime': generatedTime,
          'teacherLocation':
              GeoPoint(teacherPosition!.latitude, teacherPosition!.longitude),
          'otp': otp,
          'teacherName': teacherName,
          'presentStudents': presentStudents
        });
        print("Lecture count incremented for subject: $valueChoose");
      } else {
        await subjectDoc.set({
          'otp': otp,
          'subject': valueChoose,
          'startTime': startTime,
          'endTime': endTime,
          'generatedTime': generatedTime,
          'teacherLocation':
              GeoPoint(teacherPosition!.latitude, teacherPosition!.longitude),
          'TotalLectures': 1,
          'teacherName': teacherName,
          'presentStudents': presentStudents
        });
      }
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

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Define location settings with a balanced accuracy level
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // Adjust based on your needs
        distanceFilter: 10, // Update location every 10 meters (optional)
      );

      // Try to get the last known position and force a new location fetch if needed
      teacherPosition = await Geolocator.getLastKnownPosition();
      teacherPosition ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      StreamSubscription<Position> positionStream =
          Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            teacherPosition = position;
          });
          print(
              "Updated Position: ${position.latitude}, ${position.longitude}");
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
          content: Text(
              'This app requires location access to generate the OTP. Please allow access.'),
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
          content: Text(
              'You have permanently denied location access. Please enable it from the app settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('Go to Settings'),
              onPressed: () {
                Geolocator.openAppSettings(); // Open app settings
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
              Text("Select Subject:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: Text('Subject:'),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down),
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
              SizedBox(height: 20),
              Text("Select Lecture Time:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('Start Time'),
                      icon: Icon(Icons.arrow_drop_down),
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
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('End Time'),
                      icon: Icon(Icons.arrow_drop_down),
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
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 100,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 35, horizontal: 20),
                    child: Text("OTP is $otp",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        if (valueChoose == null) {
                          showSnackBar('Please Select a Subject');
                        } else {
                          Navigator.pushNamed(context, '/viewAttendance',
                              arguments: valueChoose);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0486FD)),
                      child: Text(
                        'View Attendance',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
