import 'package:flutter/material.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/timetable.png",
          width: 500,
          height: 500,
        ),
      ),
    );
  }
}
