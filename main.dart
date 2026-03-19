import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/input_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const EventPlannerApp());
}

class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: InputScreen(),
    );
  }
}
