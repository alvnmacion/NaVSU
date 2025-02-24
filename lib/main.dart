import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:navsu/ui/screens/signin_page.dart';
import 'ui/screens/map_screen.dart'; // Import MapScreen

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
      return const SignIn(); // Load MapScreen
    } catch (e) {
      print('Initialization error: $e');
      return const MapScreen(); // Load MapScreen as fallback
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
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          // Return nothing while loading (keeps default native splash screen)
          return const SizedBox.shrink();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
