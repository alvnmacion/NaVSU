import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navsu/ui/screens/signin_page.dart';
import 'package:navsu/ui/screens/map_screen.dart';
import 'package:navsu/ui/screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _initialScreenFuture = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userEmail = prefs.getString('email');
      final String? userName = prefs.getString('name');
      final String? userRole = prefs.getString('role');

      if (userEmail != null && userName != null) {
        print('Existing user session found: $userName (Role: $userRole)');
        
        // Navigate based on user role
        if (userRole == 'admin') {
          return const AdminScreen();
        } else {
          return const MapScreen();
        }
      } else {
        print('No existing user session');
        return const SignIn();
      }
    } catch (e) {
      print('Error checking user session: $e');
      return const SignIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NaVSU',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 0, 0, 0),
        hintColor: const Color.fromARGB(255, 0, 0, 0),
        scaffoldBackgroundColor: const Color.fromARGB(255, 241, 241, 241),
        fontFamily: 'Poppins',
        canvasColor: Colors.transparent,
      ),
      home: FutureBuilder<Widget>(
        future: _initialScreenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            print('Error loading initial screen: ${snapshot.error}');
            return const SignIn();
          }
          return snapshot.data ?? const SignIn();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
