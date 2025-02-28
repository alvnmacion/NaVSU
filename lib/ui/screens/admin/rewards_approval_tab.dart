import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:navsu/backend/backend_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class RewardsApprovalTab extends StatefulWidget {
  const RewardsApprovalTab({super.key});

  @override
  State<RewardsApprovalTab> createState() => _RewardsApprovalTabState();
}

class _RewardsApprovalTabState extends State<RewardsApprovalTab> {
  final Backend _backend = Backend();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRedemptions = [];

  @override
  void initState() {
    super.initState();
    _loadPendingRedemptions();
  }

  Future<void> _loadPendingRedemptions() async {
    setState(() => _isLoading = true);
    
    try {
      final redemptions = await _backend.getPendingRedemptions();
      setState(() {
        _pendingRedemptions = redemptions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading pending redemptions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRedemptionStatus(String redemptionId, String status) async {
    try {
      final success = await _backend.updateRedemptionStatus(redemptionId, status);
      
      if (success) {
        // Reload data
        await _loadPendingRedemptions();
        
        // Show success message
        _showSnackBar('Redemption ${status == 'completed' ? 'approved' : 'rejected'} successfully', 
          status == 'completed' ? Colors.green : Colors.orange);
      } else {
        _showSnackBar('Failed to update redemption', Colors.red);
      }
    } catch (e) {
      debugPrint('Error updating redemption: $e');
      _showSnackBar('Error updating redemption status', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading pending redemptions...',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_pendingRedemptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline, size: 72, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'No pending reward redemptions to review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRedemptions,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRedemptions.length,
        itemBuilder: (context, index) {
          final redemption = _pendingRedemptions[index];
          
          return _buildRedemptionCard(redemption);
        },
      ),
    );
  }
  
  Widget _buildRedemptionCard(Map<String, dynamic> redemption) {
    // Extract timestamp
    final DateTime timestamp = 
        redemption['timestamp'] is Timestamp 
            ? (redemption['timestamp'] as Timestamp).toDate() 
            : DateTime.now();
    
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.yellow.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: redemption['userPhotoUrl'] != null 
                    ? CachedNetworkImageProvider(redemption['userPhotoUrl'])
                    : null,
                  child: redemption['userPhotoUrl'] == null
                    ? Text(
                        redemption['userName']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                ),
                
                const SizedBox(width: 12),
                
                // User name and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        redemption['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.yellow.shade600, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 14,
                        color: Colors.yellow.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.yellow.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reward details
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 350;
                
                if (isNarrow) {
                  // Vertical layout for narrow screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reward image
                      if (redemption['rewardImage'] != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: redemption['rewardImage'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.card_giftcard, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Reward name
                      Text(
                        redemption['rewardName'] ?? 'Unknown Reward',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Points
                      _buildInfoRow(
                        icon: Icons.stars_rounded,
                        iconColor: Colors.amber,
                        text: '${NumberFormat.decimalPattern().format(redemption['pointsUsed'] ?? 0)} points',
                        textColor: Colors.black87,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Location if available
                      if (redemption['rewardLocation'] != null && redemption['rewardLocation'].toString().isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.location_on,
                          iconColor: Colors.red.shade400,
                          text: 'Claim at: ${redemption['rewardLocation']}',
                          textColor: Colors.grey.shade700,
                        ),
                    ],
                  );
                } else {
                  // Horizontal layout for wider screens
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reward image
                      if (redemption['rewardImage'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CachedNetworkImage(
                              imageUrl: redemption['rewardImage'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.card_giftcard, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // Reward info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              redemption['rewardName'] ?? 'Unknown Reward',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Points
                            _buildInfoRow(
                              icon: Icons.stars_rounded,
                              iconColor: Colors.amber,
                              text: '${NumberFormat.decimalPattern().format(redemption['pointsUsed'] ?? 0)} points',
                              textColor: Colors.black87,
                              fontSize: 15,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Location if available
                            if (redemption['rewardLocation'] != null && redemption['rewardLocation'].toString().isNotEmpty)
                              _buildInfoRow(
                                icon: Icons.location_on,
                                iconColor: Colors.red.shade400,
                                text: 'Claim at: ${redemption['rewardLocation']}',
                                textColor: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Reject Redemption',
                        content: 'Are you sure you want to reject this redemption request?',
                        confirmLabel: 'Reject',
                        confirmColor: Colors.red,
                        onConfirm: () => _updateRedemptionStatus(redemption['id'], 'rejected'),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Approve button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showConfirmationDialog(
                        context: context,
                        title: 'Approve Redemption',
                        content: 'Are you sure you want to approve this redemption request?',
                        confirmLabel: 'Approve',
                        confirmColor: Colors.green,
                        onConfirm: () => _updateRedemptionStatus(redemption['id'], 'completed'),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    double? fontSize,
  }) {
    return Row(
      children: [
        Icon(icon, size: fontSize != null ? fontSize + 2 : 18, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
  
  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      onConfirm();
    }
  }
}
