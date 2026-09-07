import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/monitor/activity_monitor_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const WorkActivityMonitorApp());
}

class WorkActivityMonitorApp extends StatelessWidget {
  const WorkActivityMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Work Activity Monitor',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF080B18),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const ActivityMonitorScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
