import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendsure/utils/routes.dart';

class ErpLogin extends StatefulWidget {
  const ErpLogin({super.key});

  @override
  State<ErpLogin> createState() => _ErpLoginState();
}

class _ErpLoginState extends State<ErpLogin> {
  late final TextEditingController _erpController;
  late final TextEditingController _passwordController;
  bool changebtn = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _erpController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _erpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> moveToHome(BuildContext context, String loginType) async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      final erpNo = _erpController.text.trim();
      final password = _passwordController.text.trim();

      final collection = loginType == 'teacher' ? 'teacher' : 'students';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(erpNo)
            .get();

        if (userDoc.exists) {
          final storedPassword = userDoc['password'];

          if (storedPassword == password) {
            setState(() {
              changebtn = true;
            });

            // Store ERP No in SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('erpNo', erpNo);

            await Future.delayed(Duration(seconds: 1));
            Navigator.pushNamed(
              context,
              Myroutes.homeRoute,
              arguments: {'loginType': loginType},
            );
            setState(() {
              changebtn = false;
            });
          } else {
            showSnackBar('Error: Incorrect password');
          }
        } else {
          showSnackBar('Error: Invalid ERP Number');
        }
      } catch (e) {
        showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loginType =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'student';
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Text(
                "AttendSure",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                "assets/images/AttendSure Logo.png",
                width: 300,
                height: 300,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 1, horizontal: 32),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      // ERP Number Input
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "ERP Number cannot be empty";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "ERP Number",
                          filled: true,
                          fillColor: Color.fromARGB(255, 224, 223, 223),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.person),
                        ),
                        controller: _erpController,
                      ),
                      SizedBox(height: 10),
                      // Password Input
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password cannot be empty";
                          }
                          return null;
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          filled: true,
                          fillColor: Color.fromARGB(255, 224, 223, 223),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        controller: _passwordController,
                      ),
                      SizedBox(height: 30),
                      // Login Button
                      InkWell(
                        onTap: () => moveToHome(context, loginType),
                        child: AnimatedContainer(
                          duration: Duration(seconds: 1),
                          width: changebtn ? 50 : 150,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(0xFF0486FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: changebtn
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Login",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

