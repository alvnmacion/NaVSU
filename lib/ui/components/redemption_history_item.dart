import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:navsu/models/redemption.dart';
import 'package:auto_size_text/auto_size_text.dart';

class RedemptionHistoryItem extends StatelessWidget {
  final Redemption redemption;
  final bool isCompact;

  const RedemptionHistoryItem({
    super.key,
    required this.redemption,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 2 : 4,
        horizontal: 0,
      ),
      color: Colors.white, // Explicitly set card background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias, // Ensures no content overflows
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isExtremelyNarrow = width < 220;
          final bool isVeryNarrow = width < 280;
          
          // For extremely narrow screens, use stacked layout
          if (isExtremelyNarrow) {
            return _buildStackedLayout(context);
          }
          
          // For narrow screens, use simplified layout
          if (isVeryNarrow) {
            return _buildCompactLayout(context);
          }
          
          // For regular screens, use standard layout
          return _buildStandardLayout(context);
        },
      ),
    );
  }

  // Layout for extremely narrow screens (< 220px)
  Widget _buildStackedLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top section with image
        SizedBox(
          height: 100,
          child: Stack(
            children: [
              // Image as background
              Positioned.fill(
                child: _buildRewardImage(fit: BoxFit.cover),
              ),
              // Dark overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Reward name on the bottom
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: AutoSizeText(
                  redemption.rewardName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  minFontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status chip on top right
              Positioned(
                top: 8,
                right: 8,
                child: _buildStatusChip(redemption.status, true),
              ),
            ],
          ),
        ),
        // Bottom section with details
        Container(
          color: Colors.white, // Ensure background is white
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location if available (top of details section)
              if (redemption.rewardLocation != null && redemption.rewardLocation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.blue[700]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          redemption.rewardLocation!,
                          style: TextStyle(fontSize: 9, color: Colors.blue[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // Date in compact format
              Text(
                'Redeemed: ${DateFormat('MM/dd/yy').format(redemption.timestamp)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              // Points
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormat.compact().format(redemption.pointsUsed),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Layout for very narrow screens (< 280px)
  Widget _buildCompactLayout(BuildContext context) {
    return Container(
      color: Colors.white, // Ensure background is white
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 42,
              height: 42,
              child: _buildRewardImage(),
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and status in one row
                Row(
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        redemption.rewardName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildStatusChip(redemption.status, true),
                  ],
                ),
                const SizedBox(height: 4),
                // Location if available (show before date)
                if (redemption.rewardLocation != null && redemption.rewardLocation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 9, color: Colors.blue[700]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            redemption.rewardLocation!,
                            style: TextStyle(fontSize: 9, color: Colors.blue[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Date
                Text(
                  DateFormat('MM/dd/yy').format(redemption.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                // Points
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      NumberFormat.compact().format(redemption.pointsUsed),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Standard layout for normal screens
  Widget _buildStandardLayout(BuildContext context) {
    return Container(
      color: Colors.white, // Ensure background is white
      padding: const EdgeInsets.all(10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _buildRewardImage(),
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  redemption.rewardName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  minFontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Add location if available
                if (redemption.rewardLocation != null && redemption.rewardLocation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            redemption.rewardLocation!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Text(
                  'Redeemed: ${DateFormat('MMM d, yyyy').format(redemption.timestamp)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat.decimalPattern().format(redemption.pointsUsed)} points',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status chip
          const SizedBox(width: 8),
          _buildStatusChip(redemption.status, isCompact),
        ],
      ),
    );
  }
  
  // Reusable image builder
  Widget _buildRewardImage({BoxFit fit = BoxFit.cover}) {
    return redemption.rewardImage != null
        ? CachedNetworkImage(
            imageUrl: redemption.rewardImage!,
            fit: fit,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.card_giftcard, size: 20, color: Colors.grey),
            ),
          )
        : Container(
            color: Colors.grey[200],
            child: const Icon(Icons.card_giftcard, size: 20, color: Colors.grey),
          );
  }

  // Status chip with adaptable size
  Widget _buildStatusChip(String status, bool compact) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        label = compact ? 'Done' : 'Completed';
        break;
      case 'rejected':
        color = Colors.red;
        label = compact ? 'No' : 'Rejected';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        label = compact ? '...' : 'Pending';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8, 
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
