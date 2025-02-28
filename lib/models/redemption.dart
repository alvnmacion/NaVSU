import 'package:cloud_firestore/cloud_firestore.dart';

class Redemption {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final String? rewardImage;
  final String? rewardLocation; // Add location field
  final int pointsUsed;
  final DateTime timestamp;
  final String status;

  Redemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    this.rewardImage,
    this.rewardLocation, // Add location field
    required this.pointsUsed,
    required this.timestamp,
    required this.status,
  });

  factory Redemption.fromMap(Map<String, dynamic> map) {
    return Redemption(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      rewardId: map['rewardId'] ?? '',
      rewardName: map['rewardName'] ?? 'Unknown Reward',
      rewardImage: map['rewardImage'],
      rewardLocation: map['rewardLocation'], // Extract location
      pointsUsed: map['pointsUsed'] is int ? 
          map['pointsUsed'] : int.tryParse(map['pointsUsed'].toString()) ?? 0,
      timestamp: map['timestamp'] != null ? 
          (map['timestamp'] as Timestamp).toDate() : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'rewardImage': rewardImage,
      'rewardLocation': rewardLocation, // Add location field
      'pointsUsed': pointsUsed,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}
