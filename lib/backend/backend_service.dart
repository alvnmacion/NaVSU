import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend service for managing app data operations
class Backend {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton pattern
  static final Backend _instance = Backend._internal();
  factory Backend() => _instance;
  Backend._internal();
  
  /// Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Check if a user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;
  
  /// Get user document reference
  DocumentReference? getUserDocRef() {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }
  
  /// Get user data as a stream
  Stream<DocumentSnapshot>? getUserDataStream() {
    final userRef = getUserDocRef();
    if (userRef == null) return null;
    return userRef.snapshots();
  }
  
  /// Get user data as a future
  Future<Map<String, dynamic>?> getUserData() async {
    final userRef = getUserDocRef();
    if (userRef == null) return null;
    
    try {
      final doc = await userRef.get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }
  
  /// Get landmark data
  Future<List<Map<String, dynamic>>> getLandmarks() async {
    try {
      final snapshot = await _firestore
          .collection('landmarks')
          .where('status', isEqualTo: 'approved')
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error fetching landmarks: $e');
      return [];
    }
  }
  
  /// Search landmarks by name
  Future<List<Map<String, dynamic>>> searchLandmarks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final snapshot = await _firestore
          .collection('landmarks')
          .where('status', isEqualTo: 'approved')
          .get();
      
      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => 
              data['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return results;
    } catch (e) {
      print('Error searching landmarks: $e');
      return [];
    }
  }
  
  /// Get rewards data
  Future<List<Map<String, dynamic>>> getAvailableRewards() async {
    try {
      final snapshot = await _firestore
          .collection('rewards')
          .where('quantity', isGreaterThan: 0)
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;  // Add document ID
            return data;
          })
          .toList();
    } catch (e) {
      print('Error fetching rewards: $e');
      return [];
    }
  }
  
  /// Get user redemption history
  Future<List<Map<String, dynamic>>> getUserRedemptionHistory() async {
    final uid = currentUserId;
    if (uid == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('redeem_history')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;  // Add document ID
            return data;
          })
          .toList();
    } catch (e) {
      print('Error fetching redemption history: $e');
      return [];
    }
  }
  
  /// Get top users for leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('distance', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;  // Add document ID
            return data;
          })
          .toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }
  
  /// Update user profile data
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? email,
  }) async {
    final userRef = getUserDocRef();
    if (userRef == null) return false;
    
    try {
      // Update Firestore document
      await userRef.update({
        if (displayName != null) 'name': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (email != null) 'email': email,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      if (displayName != null) await prefs.setString('name', displayName);
      if (photoUrl != null) await prefs.setString('photoUrl', photoUrl);
      if (email != null) await prefs.setString('email', email);
      
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  /// Add new landmark
  Future<String?> addLandmark(Map<String, dynamic> landmarkData) async {
    try {
      // Add created_at and status fields
      landmarkData['created_at'] = FieldValue.serverTimestamp();
      landmarkData['status'] = 'pending';
      
      // Add user ID of creator
      if (currentUserId != null) {
        landmarkData['creator_id'] = currentUserId;
      }
      
      // Add to Firestore
      DocumentReference docRef = await _firestore
          .collection('landmarks')
          .add(landmarkData);
          
      return docRef.id;
    } catch (e) {
      print('Error adding landmark: $e');
      return null;
    }
  }
  
  /// Redeem reward
  Future<bool> redeemReward(String rewardId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    
    try {
      bool success = false;
      
      // Run transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Get user document
        final userDoc = await transaction.get(
          _firestore.collection('users').doc(uid)
        );
        
        if (!userDoc.exists) {
          throw Exception('User document not found');
        }
        
        // Get reward document
        final rewardDoc = await transaction.get(
          _firestore.collection('rewards').doc(rewardId)
        );
        
        if (!rewardDoc.exists) {
          throw Exception('Reward not found');
        }
        
        // Extract data
        final userData = userDoc.data()!;
        final rewardData = rewardDoc.data()!;
        
        // Extract points and check if user has enough
        final userPoints = userData['points'] is int ? 
            userData['points'] : int.tryParse(userData['points'].toString()) ?? 0;
            
        final rewardPoints = rewardData['points'] is int ?
            rewardData['points'] : int.tryParse(rewardData['points'].toString()) ?? 0;
            
        final quantity = rewardData['quantity'] ?? 0;
        
        if (userPoints < rewardPoints) {
          throw Exception('Insufficient points');
        }
        
        if (quantity <= 0) {
          throw Exception('Reward out of stock');
        }
        
        // Update user points
        transaction.update(userDoc.reference, {
          'points': userPoints - rewardPoints,
        });
        
        // Update reward quantity
        transaction.update(rewardDoc.reference, {
          'quantity': quantity - 1,
        });
        
        // Create redemption record - now with more data
        transaction.set(_firestore.collection('redeem_history').doc(), {
          'userId': uid,
          'userName': userData['name'] ?? 'User',
          'userPhotoUrl': userData['photoUrl'], // Add user photo URL
          'rewardId': rewardId,
          'rewardName': rewardData['name'],
          'rewardImage': rewardData['photoUrl'],
          'rewardLocation': rewardData['location'], // Include reward location
          'pointsUsed': rewardPoints,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
        
        success = true;
      });
      
      return success;
    } catch (e) {
      print('Error redeeming reward: $e');
      return false;
    }
  }
  
  /// Record traveled distance
  Future<bool> recordDistance(double distanceKm, int earnedPoints) async {
    final uid = currentUserId;
    if (uid == null) return false;
    
    try {
      // Create history record
      await _firestore.collection('points_history').add({
        'userId': uid,
        'distance': distanceKm,
        'points': earnedPoints,
        'type': 'distance',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update user document
      final userRef = _firestore.collection('users').doc(uid);
      await userRef.update({
        'points': FieldValue.increment(earnedPoints),
        'distance': FieldValue.increment(distanceKm),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      final currentPoints = prefs.getInt('points') ?? 0;
      final currentDistance = prefs.getDouble('distance') ?? 0.0;
      
      await prefs.setInt('points', currentPoints + earnedPoints);
      await prefs.setDouble('distance', currentDistance + distanceKm);
      
      return true;
    } catch (e) {
      print('Error recording distance: $e');
      return false;
    }
  }
  
  /// Update landmark approval status
  Future<bool> updateLandmarkStatus(String landmarkId, String status) async {
    try {
      await _firestore.collection('landmarks').doc(landmarkId).update({
        'status': status,
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewer_id': currentUserId,
      });
      return true;
    } catch (e) {
      print('Error updating landmark status: $e');
      return false;
    }
  }
  
  /// Update redemption status
  Future<bool> updateRedemptionStatus(String redemptionId, String status) async {
    try {
      await _firestore.collection('redeem_history').doc(redemptionId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': currentUserId,
      });
      return true;
    } catch (e) {
      print('Error updating redemption status: $e');
      return false;
    }
  }
  
  /// Get all pending landmark approvals
  Future<List<Map<String, dynamic>>> getPendingLandmarks() async {
    try {
      final snapshot = await _firestore
          .collection('landmarks')
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching pending landmarks: $e');
      return [];
    }
  }
  
  /// Get all pending redemptions
  Future<List<Map<String, dynamic>>> getPendingRedemptions() async {
    try {
      final snapshot = await _firestore
          .collection('redeem_history')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching pending redemptions: $e');
      return [];
    }
  }
}
