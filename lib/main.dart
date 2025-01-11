import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:leaflet_test/firebase_options.dart';
import 'package:leaflet_test/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: login_p(),
    );
  }
}
