import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class RewardRedemptionDialog extends StatelessWidget {
  final String rewardName;
  final int rewardPoints;
  final String? rewardImage;
  final int userPoints;

  const RewardRedemptionDialog({
    super.key,
    required this.rewardName,
    required this.rewardPoints,
    this.rewardImage,
    required this.userPoints,
  });

  @override
  Widget build(BuildContext context) {
    final int remainingPoints = userPoints - rewardPoints;
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate optimal dialog size based on screen
    final double dialogWidth = screenSize.width * 0.85;
    final double dialogHeight = screenSize.height * 0.7;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Background blur effect
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
              
              // Main dialog content with constrained size
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isNarrow = constraints.maxWidth < 320;
                        final double maxHeight = dialogHeight * 0.9;
                        
                        // Calculate optimal image height (35% of available height)
                        final double imageHeight = maxHeight * 0.35;
                        
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image section with overlay
                            SizedBox(
                              height: imageHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Main image
                                  SizedBox.expand(
                                    child: rewardImage != null
                                      ? CachedNetworkImage(
                                          imageUrl: rewardImage!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[200],
                                            child: const Center(child: CircularProgressIndicator()),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.yellow.shade50,
                                            child: Icon(
                                              Icons.card_giftcard,
                                              size: 80,
                                              color: Colors.yellow.shade200,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.yellow.shade50,
                                          child: Icon(
                                            Icons.card_giftcard,
                                            size: 80,
                                            color: Colors.yellow.shade200,
                                          ),
                                        ),
                                  ),
                                  
                                  // Gradient overlay for better text visibility
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                          stops: const [0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Title and reward name overlay at bottom
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Title
                                        AutoSizeText(
                                          'Confirm Redemption',
                                          style: TextStyle(
                                            fontSize: isNarrow ? 18 : 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 3,
                                                color: Colors.black.withOpacity(0.5),
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          minFontSize: 16,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Reward name
                                        AutoSizeText(
                                          rewardName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2,
                                                color: Colors.black,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          minFontSize: 13,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Points info section
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Points summary
                                  Container(
                                    padding: EdgeInsets.all(isNarrow ? 12 : 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _buildPointsRow(
                                          'Current Points',
                                          userPoints,
                                          Icons.account_balance_wallet_outlined,
                                          isNarrow: isNarrow,
                                        ),
                                        Divider(
                                          height: isNarrow ? 16 : 24,
                                          thickness: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                        _buildPointsRow(
                                          'Redemption Cost',
                                          rewardPoints,
                                          Icons.remove_circle_outline,
                                          isNegative: true,
                                          isNarrow: isNarrow,
                                        ),
                                        Divider(
                                          height: isNarrow ? 16 : 24,
                                          thickness: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                        _buildPointsRow(
                                          'Remaining Points',
                                          remainingPoints,
                                          Icons.check_circle_outline,
                                          textColor: remainingPoints >= 0 ? Colors.green : Colors.red,
                                          isNarrow: isNarrow,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  SizedBox(height: isNarrow ? 16 : 20),
                                  
                                  // Action buttons
                                  Row(
                                    children: [
                                      // Cancel button
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Confirm button
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: remainingPoints >= 0 
                                            ? () => Navigator.of(context).pop(true)
                                            : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.yellow[800],
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: Colors.grey[300],
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Confirm',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsRow(String label, int points, IconData icon, 
      {bool isNegative = false, Color? textColor, bool isNarrow = false}) {
      
    final formattedPoints = NumberFormat.decimalPattern().format(points.abs());
    final textSize = isNarrow ? 13.0 : 14.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Label with icon
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Icon(
                icon, 
                size: isNarrow ? 18 : 20, 
                color: textColor ?? Colors.grey[700]
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AutoSizeText(
                  label,
                  style: TextStyle(
                    color: textColor ?? Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: textSize,
                  ),
                  maxLines: 1,
                  minFontSize: textSize - 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // Points value
        Expanded(
          flex: 2,
          child: AutoSizeText(
            isNegative ? '- $formattedPoints' : formattedPoints,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: textSize + 2,
              color: textColor ?? (isNegative ? Colors.red : Colors.black),
            ),
            maxLines: 1,
            minFontSize: textSize,
          ),
        ),
      ],
    );
  }
}
