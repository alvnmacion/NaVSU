import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:navsu/ui/dialog/admin_dialogs/admin_action_dialogs.dart';
import 'package:navsu/ui/dialog/admin_dialogs/reward_dialog.dart';

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rewards').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rewards = snapshot.data!.docs;
          
          if (rewards.isEmpty) {
            return const Center(child: Text('No rewards available.'));
          }

          final screenWidth = MediaQuery.of(context).size.width;
          
          if (screenWidth < 600) {
            return _buildListView(context, rewards);
          } else {
            return _buildGridView(context, rewards);
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRewardDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Reward', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<QueryDocumentSnapshot> rewards) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index].data() as Map<String, dynamic>;
          final rewardId = rewards[index].id;
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showEditRewardDialog(context, rewards[index]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 140,
                          child: CachedNetworkImage(
                            imageUrl: reward['photoUrl'] ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image_outlined, size: 40),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Text(
                          reward['name'] ?? 'Unnamed Reward',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                NumberFormat.compact().format(reward['points'] ?? 0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (reward['quantity'] ?? 0) > 0 
                                ? Colors.green.withOpacity(0.8)
                                : Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${reward['quantity'] ?? 0} left',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reward['location'] != null && reward['location'].toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Claim at: ${reward['location']}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showEditRewardDialog(context, rewards[index]),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                foregroundColor: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showDeleteConfirmation(context, rewards[index]),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<QueryDocumentSnapshot> rewards) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index].data() as Map<String, dynamic>;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showEditRewardDialog(context, rewards[index]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: CachedNetworkImage(
                        imageUrl: reward['photoUrl'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${reward['quantity'] ?? 0} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              NumberFormat.compact().format(reward['points'] ?? 0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward['name'] ?? 'Unnamed Reward',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (reward['location'] != null && reward['location'].toString().isNotEmpty)
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reward['location'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _showEditRewardDialog(context, rewards[index]),
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.blue,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Edit',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(context, rewards[index]),
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _showAddRewardDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => RewardDialog(
        title: 'Add Reward',
        submitText: 'Add',
        onSave: (name, points, quantity, photoUrl, location) async {  // Updated parameter list
          await FirebaseFirestore.instance.collection('rewards').add({
            'name': name,
            'points': points,
            'quantity': quantity,
            'photoUrl': photoUrl,
            'location': location,  // Save location field
            'created_at': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }

  Future<void> _showEditRewardDialog(BuildContext context, DocumentSnapshot reward) async {
    final data = reward.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => RewardDialog(
        title: 'Edit Reward',
        submitText: 'Save',
        initialName: data['name'],
        initialPoints: data['points'].toString(),
        initialQuantity: data['quantity'].toString(),
        initialPhotoUrl: data['photoUrl'],
        initialLocation: data['location'],  // Pass the existing location
        onSave: (name, points, quantity, photoUrl, location) async {  // Updated parameter list
          await reward.reference.update({
            'name': name,
            'points': points,
            'quantity': quantity,
            'photoUrl': photoUrl,
            'location': location,  // Update location field
          });
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, DocumentSnapshot reward) async {
    final data = reward.data() as Map<String, dynamic>;
    final confirmed = await AdminActionDialogs.showDeleteRewardConfirmation(
      context,
      data['name'],
    );
    
    if (confirmed) {
      await reward.reference.delete();
    }
  }
}
