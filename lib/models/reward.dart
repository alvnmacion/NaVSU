class Reward {
  final String id;
  final String name;
  final int points;
  final int quantity;
  final String? photoUrl;
  final String? location; // Added location field
  final DateTime? createdAt;

  Reward({
    required this.id,
    required this.name,
    required this.points,
    required this.quantity,
    this.photoUrl,
    this.location, // Added location parameter
    this.createdAt,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      points: map['points'] is int ? 
          map['points'] : int.tryParse(map['points'].toString()) ?? 0,
      quantity: map['quantity'] is int ? 
          map['quantity'] : int.tryParse(map['quantity'].toString()) ?? 0,
      photoUrl: map['photoUrl'],
      location: map['location'], // Extract location field
      createdAt: map['created_at'] != null ? 
          (map['created_at'] as dynamic).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'points': points,
      'quantity': quantity,
      'photoUrl': photoUrl,
      'location': location, // Include location in map
    };
  }
}
