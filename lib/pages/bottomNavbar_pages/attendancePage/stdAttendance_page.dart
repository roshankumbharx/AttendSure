import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class StdattendancePage extends StatefulWidget {
  const StdattendancePage({super.key});

  @override
  State<StdattendancePage> createState() => _StdattendancePageState();
}

class _StdattendancePageState extends State<StdattendancePage> {
  String? erpNo;
  String? valueChoose;
  Position? currentPosition;
  late final TextEditingController _otpController;
  dynamic attendedLectures = 1;
  late dynamic attendanceRecInstance;

  late StreamSubscription<Position> positionStream;

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchAttendanceRecords(
      String subject) async {
    attendanceRecInstance = await FirebaseFirestore.instance
        .collection('attendanceRecords')
        .doc(subject)
        .get();

    return attendanceRecInstance;
  }

  Future<void> _loadErpNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      erpNo = prefs.getString('erpNo');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadErpNo();
    _otpController = TextEditingController();
    startLocationStream();
  }

  @override
  void dispose() {
    _otpController.dispose();
    positionStream.cancel(); // Cancel the stream when the widget is disposed
    super.dispose();
  }

  List<String> subjects = [
    'AI',
    'Web Computing (WC)',
    'Computer Network (CN)',
    'DWM',
    'SAIDS',
    'IOT'
  ];

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update only if the location changes by 10 meter
    );
    Position stdCurrentloc =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    return stdCurrentloc;
  }

  // Start streaming location updates
  void startLocationStream() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Set minimum distance for updates
    );

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if(mounted){
      setState(() {
        currentPosition = position;
      });
      }
    });
  }

  // Check if OTP, location, and time match
  Future<bool> checkConditions(
      String enteredOtp, Map<String, dynamic> data) async {
    if (enteredOtp != data['otp'].toString()) {
      showSnackBar('Wrong OTP entered');
      return false;
    }
    DateTime currentTime = DateTime.now();
    Timestamp storedTimestamp = data['generatedTime'];
    DateTime storedTime = storedTimestamp.toDate();
    Duration timeDifference = currentTime.difference(storedTime);

    if (timeDifference.inSeconds > 120) {
      showSnackBar('Took too long to enter the OTP');
      return false;
    }

    currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      showSnackBar('Location is null');
      return false;
    }

    GeoPoint teacherLocation = data['teacherLocation'];
    double teacherLatitude = teacherLocation.latitude;
    double teacherLongitude = teacherLocation.longitude;

    double distance = Geolocator.distanceBetween(
      teacherLatitude,
      teacherLongitude,
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    DocumentReference subjectColl =
        FirebaseFirestore.instance.collection(erpNo!).doc(valueChoose);

    DocumentSnapshot collSnapshot = await subjectColl.get();
    if (collSnapshot.exists) {
      await subjectColl.update({
        'stdLocation':
            GeoPoint(currentPosition!.latitude, currentPosition!.longitude),
      });
    }

    if (distance > 50) {
      showSnackBar('Out of bounds');
      return false;
    }
    return true; // All conditions met
  }

 Future<void> markAttendance(
    String subject, String erpNo, Position currentPosition) async {
  try {
    // Fetch attendance record for the subject
    DocumentReference attendanceRecordRef = FirebaseFirestore.instance
        .collection('attendanceRecords')
        .doc(subject);
    DocumentSnapshot attendanceRecord = await attendanceRecordRef.get();

    if (!attendanceRecord.exists) {
      print('Attendance record for subject $subject does not exist.');
      return;
    }

    int totalLectures = attendanceRecord['TotalLectures'];

    // Fetch the student's attendance record for the subject
    DocumentReference studentAttendanceRef = FirebaseFirestore.instance
        .collection('studentAttendance')
        .doc(erpNo)
        .collection('subjects')
        .doc(subject);

    DocumentSnapshot studentAttendance = await studentAttendanceRef.get();
    int attendedLectures = studentAttendance.exists
        ? studentAttendance['attendedLectures'] ?? 0
        : 0;

    // Check if the student's name is already in the presentStudents list
    List<dynamic> presentStudents =
        attendanceRecord['presentStudents'] ?? [];

    // Fetch the student's name based on the ERP No
    DocumentSnapshot studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(erpNo)
        .get();

    if (!studentDoc.exists) {
      print('Student with ERP No: $erpNo does not exist.');
      return;
    }

    String studentName = studentDoc['name']; // Get student name

    if (presentStudents.contains(studentName)) {
      // Show snackbar indicating attendance has already been marked
      showSnackBar('Attendance already marked for $studentName.');
      return; // Stop execution here
    }

    // Otherwise, mark the attendance
    attendedLectures += 1;
    double attendancePercentage = ((attendedLectures / totalLectures) * 100);
    attendancePercentage = double.parse(attendancePercentage.toStringAsFixed(2));

    // Get student's current location
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      showSnackBar('Unable to get location');
      return;
    }

    GeoPoint studentLocation =
        GeoPoint(currentPosition.latitude, currentPosition.longitude);

    // Update or set the student's attendance data
    if (studentAttendance.exists) {
      await studentAttendanceRef.update({
        'attendedLectures': attendedLectures,
        'attendancePercentage': attendancePercentage,
        'stdLocation': studentLocation,
      });
    } else {
      await studentAttendanceRef.set({
        'subject': subject,
        'attendedLectures': attendedLectures,
        'attendancePercentage': attendancePercentage,
        'stdLocation': studentLocation,
      });
    }

    // Add student's name to the presentStudents list
    presentStudents.add(studentName);

    // Update the 'presentStudents' list in the Firestore document
    await attendanceRecordRef.update({
      'presentStudents': presentStudents,
    });
  } catch (e) {
    print("Error marking attendance: $e");
  }
}
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: double.infinity,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 80, left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Select Subject:",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 20),
                const Text('Lecture Timing : ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                if (valueChoose != null)
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: fetchAttendanceRecords(valueChoose!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(snapshot.error.toString(),
                            style: TextStyle(fontSize: 20));
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('No records found.');
                      }
                      final data = snapshot.data!.data();
                      if (data == null) {
                        return const Text('No data available');
                      }
                      return Column(
                        children: [
                          Text(
                            '${data['startTime'] ?? 'N/A'} to ${data['endTime'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                          const Text('Lecture Coordinator:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 24)),
                          Text('Prof. ${data['teacherName'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              labelText: 'Enter OTP',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              // Ensure location services are enabled
                              bool serviceEnabled =
                                  await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) {
                                showSnackBar(
                                    'Please enable location services to mark attendance.');

                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Location Required'),
                                    content: Text(
                                        'Location services are required to mark attendance. Please enable location services.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Geolocator.openLocationSettings();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Open Settings'),
                                      ),
                                    ],
                                  ),
                                );
                                return; // Stop further execution until location is enabled
                              }
                              // Get the entered OTP and the fetched OTP from Firestore
                              print('Fetched otp: ${data['otp']}');
                              print('Entered otp: ${_otpController.text}');
                              // Fetch current location and update it in Firestore
                              Position? currentPosition =
                                  await getCurrentLocation();
                              if (currentPosition == null) {
                                showSnackBar(
                                    'Unable to get location, location==null');
                                return; // Stop if unable to get current location
                              }
                              // Now check if the OTP and other conditions (location and time) are met
                              bool conditionsMet = await checkConditions(
                                  _otpController.text, data);

                              if (conditionsMet) {
                                await markAttendance(
                                    valueChoose!, erpNo!, currentPosition);
                                showSnackBar('Attendance Marked!');
                                _otpController.clear();
                              } else {
                                showSnackBar('Conditions not met. Try again.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0486FD),
                            ),
                            child: const Text(
                              'Mark Attendance',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          )
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
