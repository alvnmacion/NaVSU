import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added import
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import
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
      // Check if user is logged in with Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        print('User logged in: ${currentUser.uid}');
        
        // Fetch fresh data from Firestore
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          if (userDoc.exists) {
            // User exists in database
            final userData = userDoc.data()!;
            final String userRole = userData['role'] ?? 'user';
            
            // Update SharedPreferences with latest data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('uid', currentUser.uid);
            await prefs.setString('email', currentUser.email ?? '');
            await prefs.setString('name', userData['name'] ?? currentUser.displayName ?? 'User');
            await prefs.setString('role', userRole);
            
            // Store photo URL
            if (userData['photoUrl'] != null) {
              await prefs.setString('photoUrl', userData['photoUrl']);
            } else if (currentUser.photoURL != null) {
              await prefs.setString('photoUrl', currentUser.photoURL!);
            }
            
            // Store points and distance
            if (userData['points'] != null) {
              final int points = userData['points'] is int ? 
                userData['points'] : int.tryParse(userData['points'].toString()) ?? 0;
              await prefs.setInt('points', points);
            }
            
            if (userData['distance'] != null) {
              final double distance = userData['distance'] is double ? 
                userData['distance'] : double.tryParse(userData['distance'].toString()) ?? 0.0;
              await prefs.setDouble('distance', distance);
            }
            
            print('User data loaded and cached: ${userData['name']}, role: $userRole');
            
            // Navigate based on role
            if (userRole == 'admin') {
              return const AdminScreen();
            } else {
              return const MapScreen();
            }
          } else {
            // User exists in Auth but not in Firestore
            print('User not found in database, creating new profile');
            
            // Create new user document
            await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
              'uid': currentUser.uid,
              'email': currentUser.email,
              'name': currentUser.displayName ?? 'User',
              'photoUrl': currentUser.photoURL,
              'role': 'user',
              'points': 0,
              'distance': 0.0,
              'created_at': FieldValue.serverTimestamp(),
            });
            
            // Store in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('uid', currentUser.uid);
            await prefs.setString('email', currentUser.email ?? '');
            await prefs.setString('name', currentUser.displayName ?? 'User');
            await prefs.setString('role', 'user');
            if (currentUser.photoURL != null) {
              await prefs.setString('photoUrl', currentUser.photoURL!);
            }
            await prefs.setInt('points', 0);
            await prefs.setDouble('distance', 0.0);
            
            return const MapScreen();
          }
        } catch (e) {
          print('Error fetching user data from Firestore: $e');
          // If Firestore fetch fails, fall back to cached data
          final prefs = await SharedPreferences.getInstance();
          final String? userRole = prefs.getString('role');
          
          if (userRole == 'admin') {
            return const AdminScreen();
          } else if (prefs.getString('email') != null) {
            return const MapScreen();
          } else {
            return const SignIn();
          }
        }
      } else {
        // No user logged in with Firebase Auth
        print('No authenticated user found');
        return const SignIn();
      }
    } catch (e) {
      print('Error determining initial screen: $e');
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
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo or icon
                    Image.asset(
                      'assets/images/applogo.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.map, size: 80, color: Colors.green),
                    ),
                    const SizedBox(height: 24),
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 16),
                    // Loading text
                    Text(
                      'Loading NaVSU...',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
