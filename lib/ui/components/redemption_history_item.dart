import 'package:flutter/material.dart';
import 'package:navsu/models/redemption.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // For base64 conversion
import 'dart:typed_data'; // For Uint8List

class RedemptionHistoryItem extends StatelessWidget {
  final Redemption redemption;
  final bool isCompact;

  const RedemptionHistoryItem({
    super.key,
    required this.redemption,
    this.isCompact = false,
  });

  // Helper method to convert base64 image to bytes
  Uint8List? _getImageBytes(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    
    try {
      if (photoUrl.startsWith('data:image')) {
        // Extract the base64 part (after the comma)
        final base64String = photoUrl.split(',')[1];
        return base64Decode(base64String);
      }
    } catch (e) {
      debugPrint('Error decoding image: $e');
    }
    return null;
  }

  // Build image widget for redemption history
  Widget _buildImage(BuildContext context) {
    final imageBytes = _getImageBytes(redemption.rewardImage);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: isCompact ? 60 : 70,
        height: isCompact ? 60 : 70,
        child: imageBytes != null
            ? Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, trace) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.card_giftcard,
          size: isCompact ? 30 : 35,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format date for display
    final DateTime timestamp = redemption.timestamp ?? DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - now using byte array conversion
            _buildImage(context),
            
            SizedBox(width: isCompact ? 8 : 12),
            
            // Details section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    redemption.rewardName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 14 : 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isCompact ? 2 : 4),
                  
                  // Date and time
                  Text(
                    dateFormat.format(timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isCompact ? 11 : 12,
                    ),
                  ),
                  
                  SizedBox(height: isCompact ? 4 : 6),
                  
                  // Points and status
                  Row(
                    children: [
                      // Points used
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 8,
                          vertical: isCompact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars,
                              size: isCompact ? 12 : 14,
                              color: Colors.amber[800],
                            ),
                            SizedBox(width: isCompact ? 2 : 4),
                            Text(
                              '${NumberFormat.compact().format(redemption.pointsUsed)} points',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: isCompact ? 11 : 12,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(width: isCompact ? 6 : 8),
                      
                      // Status pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 8,
                          vertical: isCompact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(redemption.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          redemption.status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 10 : 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Location if available
                  if (redemption.rewardLocation != null && 
                      redemption.rewardLocation!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: isCompact ? 4 : 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: isCompact ? 14 : 16,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Claim at: ${redemption.rewardLocation}',
                              style: TextStyle(
                                fontSize: isCompact ? 11 : 12,
                                color: Colors.blue[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
