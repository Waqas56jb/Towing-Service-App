import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:test_drive/firebase_options.dart';
import 'screens/get_started_screen.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart'; // Import the DashboardPage

void main() async {
  // Ensure the Flutter binding is initialized before calling any async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run your app after Firebase initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuneUp App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Color(0xFF0C0C0C),
      ),
      // You can set DashboardPage as the initial route
      initialRoute:
          '/', // Change to '/dashboard' to open it initially, or '/login' to start with login page
      routes: {
        '/': (context) => const GetStartedScreen(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard':
            (context) =>
                const DashboardScreen(), // Add DashboardPage route here
      },
    );
  }
}
