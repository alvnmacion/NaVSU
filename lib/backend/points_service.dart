import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Points earned per km
  static const int pointsPerKm = 1000;
  
  // Minimum distance to earn points (in km)
  static const double minDistanceForPoints = 0.00; // 50 meters
  
  Future<void> recordDistanceTraveled(double distanceKm) async {
    // Skip if distance is too small
    if (distanceKm < minDistanceForPoints) {
      print('Distance too small to record: $distanceKm km');
      return;
    }
    
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No authenticated user found');
      return;
    }
    
    final String userId = currentUser.uid;
    print('Current user ID: $userId');
    
    try {
      // Important: Use the exact distanceKm value passed in - don't round again
      // This ensures the points calculation matches what's shown in the dialog
      
      // Calculate points earned - use the same formula as in MapScreen
      final int pointsEarned = (distanceKm * pointsPerKm).round();

      print('Recording exact values - distance: $distanceKm km, points: $pointsEarned for user: $userId');
      
      // First, create record in points history with exact values
      try {
        DocumentReference historyRef = await _firestore.collection('points_history').add({
          'userId': userId,
          'distance': distanceKm, // Store the exact value
          'points': pointsEarned, // Store the exact calculated points
          'type': 'distance',
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Points history document added with ID: ${historyRef.id}');
      } catch (e) {
        print('Error adding points history: $e');
      }
      
      // Now update or create the user document directly without transaction
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      
      // Try to get the document first
      DocumentSnapshot userDoc;
      try {
        userDoc = await userRef.get();
      } catch (e) {
        print('Error getting user document: $e');
        userDoc = await userRef.get(); // Try one more time
      }
      
      // If document exists, update it. Otherwise create it.
      try {
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
          
          int currentPoints = 0;
          double currentDistance = 0.0;
          
          if (userData != null) {
            // Handle potential null or wrong type values
            if (userData['points'] != null) {
              currentPoints = (userData['points'] is int) ? 
                  userData['points'] : int.tryParse(userData['points'].toString()) ?? 0;
            }
            
            if (userData['distance'] != null) {
              currentDistance = (userData['distance'] is double) ? 
                  userData['distance'] : double.tryParse(userData['distance'].toString()) ?? 0.0;
            }
          }
          
          print('Current values - Points: $currentPoints, Distance: $currentDistance');
          print('Adding - Points: $pointsEarned, Distance: $distanceKm');
          
          await userRef.update({
            'points': currentPoints + pointsEarned,
            'distance': currentDistance + distanceKm,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          print('User document updated successfully');
        } else {
          // Create new document
          print('User document does not exist. Creating new one.');
          await userRef.set({
            'uid': userId,
            'email': currentUser.email,
            'name': currentUser.displayName ?? 'User',
            'photoUrl': currentUser.photoURL,
            'points': pointsEarned,
            'distance': distanceKm,
            'created_at': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          print('New user document created successfully');
        }
      } catch (e) {
        print('Error updating user document: $e');
        // Try one more direct approach
        try {
          await _firestore.collection('users').doc(userId).set({
            'points': FieldValue.increment(pointsEarned),
            'distance': FieldValue.increment(distanceKm),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          print('User document updated via merge');
        } catch (finalError) {
          print('Final attempt failed: $finalError');
        }
      }
      
      // Update local cache
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        
        // Update points
        int currentPoints = prefs.getInt('points') ?? 0;
        int newPoints = currentPoints + pointsEarned;
        await prefs.setInt('points', newPoints);
        
        // Update distance
        double currentDistance = prefs.getDouble('distance') ?? 0.0;
        double newDistance = currentDistance + distanceKm;
        await prefs.setDouble('distance', newDistance);
        
        print('Local cache updated, new points: $newPoints, new distance: $newDistance km');
      } catch (e) {
        print('Error updating local cache: $e');
      }
      
    } catch (e) {
      print('Error in recordDistanceTraveled: $e');
    }
  }
}
