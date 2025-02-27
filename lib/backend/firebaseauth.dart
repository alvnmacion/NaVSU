import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // Check if the user is new and set a default role
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(user?.uid).set({
          'role': 'user', // Default role
          'email': user?.email,
          'name': user?.displayName,
          'photoUrl': user?.photoURL,
          'points': 0,
        });
      }

      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<String> getUserRole(User user) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
      } else {
        // Create new user document with default role
        await _firestore.collection('users').doc(user.uid).set({
          'role': 'user',
          'email': user.email,
          'name': user.displayName,
          'photoUrl': user.photoURL,
          'points': 0,
          'distance': 0,
        });
        return 'user';
      }
    } catch (e) {
      print('Error getting user role: $e');
      return 'user'; // Default to user role on error
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Remove only user-related preferences
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('photoUrl');
    await prefs.remove('userRole');
    await prefs.remove('points');
    // ...remove other user-specific keys if any...
  }

  Future<void> saveUserDetails(User user) async {
    try {
      final role = await getUserRole(user);
      final points = await getUserPoints(user) ?? 0;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('name', user.displayName ?? '');
      await prefs.setString('photoUrl', user.photoURL ?? '');
      await prefs.setString('role', role);
      await prefs.setInt('points', points);
    } catch (e) {
      print('Error saving user details: $e');
    }
  }

  Future<int?> getUserPoints(User user) async {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc['points'] as int;
        } else {
          print('User document does not exist');
          return null;
        }
      } catch (e) {
        print(e.toString());
        return null;
      }
    }

  Future<Map<String, String?>> getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? name = prefs.getString('name');
    String? photoUrl = prefs.getString('photoUrl');
    int? points = prefs.getInt('points');
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'points': points.toString(),
    };
  }

  // Future<void> cacheUserRole(User user) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final role = await getUserRole(user);
  //   if (role != null) {
  //     await prefs.setString('userRole', role);
  //   }
  // }
}