import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:navsu/models/reward.dart';
import 'package:auto_size_text/auto_size_text.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final bool canAfford;
  final VoidCallback onTap;

  const RewardCard({
    super.key,
    required this.reward,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8), // Add bottom margin to the card
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias, // Ensures no content overflows
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine available width and adjust layout accordingly
          final double availableWidth = constraints.maxWidth;
          final bool isVeryNarrow = availableWidth < 120;
          final bool isNarrow = availableWidth < 180;
          
          // Adjust the image-to-content ratio based on width
          final int imageFlex = isVeryNarrow ? 3 : 4;
          final int contentFlex = isVeryNarrow ? 2 : 3;
          
          return InkWell(
            onTap: canAfford ? onTap : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IMAGE SECTION
                Expanded(
                  flex: imageFlex,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with error handling
                      CachedNetworkImage(
                        imageUrl: reward.photoUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.card_giftcard, color: Colors.grey),
                        ),
                      ),
                      
                      // Available count badge
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Left: ${reward.quantity}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVeryNarrow ? 8 : 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // CONTENT SECTION - Update with more flexible layout
                Expanded(
                  flex: contentFlex,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isVeryNarrow ? 4 : 8,
                      right: isVeryNarrow ? 4 : 8,
                      top: isVeryNarrow ? 2 : 4,
                      bottom: isVeryNarrow ? 6 : 10, // Add more padding at the bottom
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Use constraints to determine content spacing
                        // Make sure there's enough room for all elements
                        final double contentHeight = constraints.maxHeight;
                        final bool isTooSmall = contentHeight < 80;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title - limit height and use AutoSizeText
                            Padding(
                              padding: EdgeInsets.only(top: isVeryNarrow ? 1 : 2),
                              child: SizedBox(
                                height: isTooSmall ? contentHeight * 0.25 : contentHeight * 0.3,
                                child: AutoSizeText(
                                  reward.name,
                                  style: TextStyle(
                                    fontSize: isVeryNarrow ? 10 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 9,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            
                            // Location - show only if space permits and location exists
                            if (reward.location != null && 
                                reward.location!.isNotEmpty && 
                                !isTooSmall)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: SizedBox(
                                  height: contentHeight * 0.15,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: isVeryNarrow ? 8 : 10,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: isVeryNarrow ? 1 : 2),
                                      Expanded(
                                        child: AutoSizeText(
                                          reward.location!,
                                          style: TextStyle(
                                            fontSize: isVeryNarrow ? 7 : 9,
                                            color: Colors.grey[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          minFontSize: 6,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // Points info
                            SizedBox(
                              height: contentHeight * 0.2,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.stars_rounded, 
                                    color: Colors.amber, 
                                    size: isVeryNarrow ? 9 : 11
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: AutoSizeText(
                                      isVeryNarrow ? 
                                        NumberFormat.compact().format(reward.points) :
                                        NumberFormat.decimalPattern().format(reward.points),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: canAfford ? Colors.green : Colors.red,
                                        fontSize: isVeryNarrow ? 9 : 11,
                                      ),
                                      maxLines: 1,
                                      minFontSize: 7,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Redeem button - ensure it's properly sized
                            SizedBox(
                              height: contentHeight * 0.3,
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2), // Add small padding below button
                                child: ElevatedButton(
                                  onPressed: canAfford ? onTap : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellow[800],
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[300],
                                    padding: EdgeInsets.zero, // Remove padding for better fit
                                    minimumSize: Size.zero, // Allow button to be any size
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'Redeem',
                                        style: TextStyle(
                                          fontSize: isVeryNarrow ? 9 : 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
