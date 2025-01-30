import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrHomePage extends StatefulWidget {
  const TrHomePage({super.key});

  @override
  State<TrHomePage> createState() => _TrHomePageState();
}

class _TrHomePageState extends State<TrHomePage> {
  String? erpNo;

  Future<void> _loadErpNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      erpNo = prefs.getString('erpNo');
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getTeacherData() async {
    return await FirebaseFirestore.instance
        .collection('teacher')
        .doc(erpNo)
        .get();
  }

  @override
  void initState() {
    super.initState();
    _loadErpNo(); // Load ERP No when initializing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFE8E8E8),
        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: getTeacherData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error fetching data'));
              }

              if (!snapshot.hasData || snapshot.data?.data() == null) {
                // Handle case where no data is found or document is null
                return Center(child: Text('No data found for this teacher'));
              }

              var teacherData = snapshot.data!.data()!;

              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/Logo Ltjss.png",
                        width: 80,
                        height: 80,
                      ),
                      Column(
                        children: const [
                          Center(
                            child: Text(
                              'Lokmanya Tilak College of Engineering Navi Mumbai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Image.network(
                        teacherData['photo'],
                        width: 100,
                        height: 100,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        teacherData['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ERP NO :',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            teacherData['erpNo'],
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Branch :',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Text(
                            '${teacherData['branch']}',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 26),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0486FD)),
                            child: Text("Today's TimeTable",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }));
  }
}
