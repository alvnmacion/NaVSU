import 'package:cloud_firestore/cloud_firestore.dart';

class Redemption {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String rewardId;
  final String rewardName;
  final String? rewardImage; // This will store the base64 image string
  final String? rewardLocation;
  final int pointsUsed;
  final DateTime? timestamp;
  final String status;

  Redemption({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.rewardId,
    required this.rewardName,
    this.rewardImage,
    this.rewardLocation,
    required this.pointsUsed,
    this.timestamp,
    required this.status,
  });

  // Factory method to create a Redemption from Firestore data
  factory Redemption.fromMap(Map<String, dynamic> map) {
    // Handle timestamp conversion
    DateTime? timestamp;
    if (map['timestamp'] != null) {
      if (map['timestamp'] is Timestamp) {
        timestamp = (map['timestamp'] as Timestamp).toDate();
      } else if (map['timestamp'] is DateTime) {
        timestamp = map['timestamp'] as DateTime;
      }
    }

    return Redemption(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      userPhotoUrl: map['userPhotoUrl'],
      rewardId: map['rewardId'] ?? '',
      rewardName: map['rewardName'] ?? 'Unnamed Reward',
      rewardImage: map['rewardImage'], // Store the base64 image string as is
      rewardLocation: map['rewardLocation'],
      pointsUsed: map['pointsUsed'] is int 
          ? map['pointsUsed'] 
          : int.tryParse(map['pointsUsed'].toString()) ?? 0,
      timestamp: timestamp,
      status: map['status'] ?? 'pending',
    );
  }

  // Convert Redemption to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'rewardImage': rewardImage,
      'rewardLocation': rewardLocation,
      'pointsUsed': pointsUsed,
      'timestamp': timestamp,
      'status': status,
    };
  }
}
