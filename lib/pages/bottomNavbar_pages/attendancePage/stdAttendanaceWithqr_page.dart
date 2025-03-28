
import 'package:attendsure/pages/bottomNavbar_pages/attendancePage/qrScanner_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class StdattendanceWithQRPage extends StatefulWidget {
  const StdattendanceWithQRPage({super.key});

  @override
  State<StdattendanceWithQRPage> createState() => _StdattendanceWithQRPageState();
}

class _StdattendanceWithQRPageState extends State<StdattendanceWithQRPage> {
  String? erpNo;
  String? valueChoose;
  String? startTime;
  String? endTime;
  Position? currentPosition;
  late final TextEditingController _otpController;
  dynamic attendedLectures = 1;
  late dynamic attendanceRecInstance;
  late StreamSubscription<Position> positionStream;

  List<String> subjects = [
    'AI',
    'Web Computing (WC)',
    'Computer Network (CN)',
    'DWM',
    'SAIDS',
    'IOT'
  ];

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchAttendanceRecords(String subject) async {
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
    positionStream.cancel();
    super.dispose();
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return null;
    }
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  // Start streaming location updates
  void startLocationStream() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });
  }

  // Check if OTP, location, and time match (used for both manual OTP and QR scan)
  Future<bool> checkConditions(String enteredOtp, Map<String, dynamic> data) async {
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
    // Optionally update student's location in Firestore
    DocumentReference subjectColl =
        FirebaseFirestore.instance.collection(erpNo!).doc(valueChoose);
    DocumentSnapshot collSnapshot = await subjectColl.get();
    if (collSnapshot.exists) {
      await subjectColl.update({
        'stdLocation': GeoPoint(currentPosition!.latitude, currentPosition!.longitude),
      });
    }
    if (distance > 50) {
      showSnackBar('Out of bounds');
      return false;
    }
    return true;
  }

  Future<void> markAttendance(String subject, String erpNo, Position currentPosition) async {
    try {
      DocumentReference attendanceRecordRef = FirebaseFirestore.instance
          .collection('attendanceRecords')
          .doc(subject);
      DocumentSnapshot attendanceRecord = await attendanceRecordRef.get();
      if (!attendanceRecord.exists) {
        print('Attendance record for subject $subject does not exist.');
        return;
      }
      int totalLectures = attendanceRecord['TotalLectures'];
      DocumentReference studentAttendanceRef = FirebaseFirestore.instance
          .collection('studentAttendance')
          .doc(erpNo)
          .collection('subjects')
          .doc(subject);
      DocumentSnapshot studentAttendance = await studentAttendanceRef.get();
      int attendedLectures = studentAttendance.exists
          ? studentAttendance['attendedLectures'] ?? 0
          : 0;
      List<dynamic> presentStudents = attendanceRecord['presentStudents'] ?? [];
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(erpNo)
          .get();
      if (!studentDoc.exists) {
        print('Student with ERP No: $erpNo does not exist.');
        return;
      }
      String studentName = studentDoc['name'];
      if (presentStudents.contains(studentName)) {
        showSnackBar('Attendance already marked for $studentName.');
        return;
      }
      attendedLectures += 1;
      double attendancePercentage = ((attendedLectures / totalLectures) * 100);
      attendancePercentage = double.parse(attendancePercentage.toStringAsFixed(2));
      Position? currentPos = await getCurrentLocation();
      if (currentPos == null) {
        showSnackBar('Unable to get location');
        return;
      }
      GeoPoint studentLocation = GeoPoint(currentPos.latitude, currentPos.longitude);
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
      presentStudents.add(studentName);
      await attendanceRecordRef.update({
        'presentStudents': presentStudents,
      });
    } catch (e) {
      print("Error marking attendance: $e");
    }
  }

  // Function to mark attendance using student's name (for manual updates)
  Future<void> markAttendanceByName() async {
    if (valueChoose == null || erpNo == null) {
      showSnackBar('Subject or ERP not selected');
      return;
    }
    DocumentSnapshot studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(erpNo)
        .get();
    if (!studentDoc.exists) {
      showSnackBar('Student not found');
      return;
    }
    String studentName = studentDoc['name'];
    DocumentReference attendanceRecordRef = FirebaseFirestore.instance
        .collection('attendanceRecords')
        .doc(valueChoose);
    await attendanceRecordRef.update({
      'presentStudents': FieldValue.arrayUnion([studentName]),
      'absentstd': FieldValue.arrayRemove([studentName])
    });
    showSnackBar('Attendance marked for $studentName');
  }

  // New function that scans the QR and then marks attendance automatically
  Future<void> scanAndMarkAttendance() async {
    try {
      // Navigate to the QRScanPage and await the scanned result
      final scannedResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScanPage()),
      );
      if (scannedResult == null || scannedResult.isEmpty) {
        showSnackBar("No QR data scanned");
        return;
      }
      // Expect scanned data in the format "subject|otp|startTime|endTime"
      final parts = scannedResult.split('|');
      if (parts.length != 4) {
        showSnackBar("Invalid QR code format.");
        return;
      }
      final scannedSubject = parts[0];
      final scannedOtp = parts[1];
      // Optionally, you can retrieve scannedStartTime and scannedEndTime if needed
      if (valueChoose == null || valueChoose != scannedSubject) {
        showSnackBar("Scanned subject does not match the selected subject.");
        return;
      }
      DocumentSnapshot<Map<String, dynamic>> snapshot = await fetchAttendanceRecords(valueChoose!);
      final data = snapshot.data();
      if (data == null) {
        showSnackBar("No attendance data available");
        return;
      }
      // Optionally compare scanned data with stored QR data from Firestore:
      String storedQrData = data['qrData'] ?? "";
      if (storedQrData != scannedResult) {
        showSnackBar("Scanned QR does not match the current session.");
        return;
      }
      bool conditionsMet = await checkConditions(scannedOtp, data);
      if (!conditionsMet) {
        showSnackBar("Conditions not met. Try again.");
        return;
      }
      Position? currentPos = await getCurrentLocation();
      if (currentPos == null) {
        showSnackBar("Unable to get current location");
        return;
      }
      await markAttendance(valueChoose!, erpNo!, currentPos);
      showSnackBar("Attendance Marked via QR!");
    } catch (e) {
      showSnackBar("Error during QR scan: $e");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
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
              const Text("Select Subject:",
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
              const Text("Select Lecture Time:",
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  // Optionally, add your time selection widgets here.
                ],
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Button to mark attendance via OTP (existing approach)
                  ElevatedButton(
                    onPressed: () async {
                      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        showSnackBar('Please enable location services to mark attendance.');
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Location Required'),
                            content: const Text('Location services are required to mark attendance. Please enable location services.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Geolocator.openLocationSettings();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Open Settings'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      print('Fetched otp: ${await fetchAttendanceRecords(valueChoose!)}');
                      print('Entered otp: ${_otpController.text}');
                      Position? currentPosition = await getCurrentLocation();
                      if (currentPosition == null) {
                        showSnackBar('Unable to get location, location==null');
                        return;
                      }
                      DocumentSnapshot<Map<String, dynamic>> snapshot = await fetchAttendanceRecords(valueChoose!);
                      final data = snapshot.data();
                      if (data == null) {
                        showSnackBar('No attendance data available');
                        return;
                      }
                      bool conditionsMet = await checkConditions(_otpController.text, data);
                      if (conditionsMet) {
                        await markAttendance(valueChoose!, erpNo!, currentPosition);
                        showSnackBar('Attendance Marked!');
                        _otpController.clear();
                      } else {
                        showSnackBar('Conditions not met. Try again.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0486FD),
                    ),
                    child: const Text(
                      'Mark Attendance',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Button to scan QR and mark attendance automatically
                  ElevatedButton(
                    onPressed: () async {
                      await scanAndMarkAttendance();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0486FD),
                    ),
                    child: const Text(
                      'Scan QR',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Additional button that directly marks attendance using student's name
                  ElevatedButton(
                    onPressed: () async {
                      await markAttendanceByName();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0486FD),
                    ),
                    child: const Text(
                      'Mark Attendance (By Name)',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Optional: OTP input field for manual entry if desired
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
