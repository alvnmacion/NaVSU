import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:navsu/ui/dialog/admin_dialogs/admin_action_dialogs.dart';
import 'package:navsu/ui/dialog/admin_dialogs/reward_dialog.dart';

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key});
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

          return ListView.builder(
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index].data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: reward['photoUrl'] ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          reward['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.stars, '${reward['points']} Points'),
                            const SizedBox(height: 4),
                            _buildInfoRow(Icons.inventory_2, '${reward['quantity']} Available'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          itemBuilder: (context) => [
                            _buildPopupMenuItem('edit', Icons.edit, 'Edit'),
                            _buildPopupMenuItem('delete', Icons.delete, 'Delete'),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditRewardDialog(context, rewards[index]);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, rewards[index]);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
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
        onSave: (name, points, quantity, photoUrl) async {
          await FirebaseFirestore.instance.collection('rewards').add({
            'name': name,
            'points': points,
            'quantity': quantity,
            'photoUrl': photoUrl,
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
        onSave: (name, points, quantity, photoUrl) async {
          await reward.reference.update({
            'name': name,
            'points': points,
            'quantity': quantity,
            'photoUrl': photoUrl,
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
