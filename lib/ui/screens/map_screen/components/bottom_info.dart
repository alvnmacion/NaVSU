import 'package:flutter/material.dart';

class BottomInfo extends StatelessWidget {
  final String walkingEta;
  final String drivingEta;
  final String distance;
  final bool isNavigating;
  final VoidCallback onCancelNavigation;
  final VoidCallback onAddLandmark;

  const BottomInfo({
    Key? key,
    required this.walkingEta,
    required this.drivingEta,
    required this.distance,
    required this.isNavigating,
    required this.onCancelNavigation,
    required this.onAddLandmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isMedium = size.width >= 360 && size.width < 600;
    final isLarge = size.width >= 600;

    // Adjust sizes based on screen width
    final double horizontalPadding = isSmall ? 8 : (isMedium ? 16 : 24);
    final double verticalPadding = isSmall ? 8 : (isMedium ? 12 : 16);
    final double iconSize = isSmall ? 18 : (isMedium ? 24 : 28);
    final double titleFontSize = isSmall ? 10 : (isMedium ? 12 : 14);
    final double valueFontSize = isSmall ? 14 : (isMedium ? 16 : 18);
    final double buttonFontSize = isSmall ? 10 : (isMedium ? 11 : 12);
    final double buttonPadding = isSmall ? 8 : (isMedium ? 12 : 16);
    final double spacing = isSmall ? 8 : (isMedium ? 12 : 16);

    return Container(
      margin: EdgeInsets.all(horizontalPadding),
      padding: EdgeInsets.all(verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoColumn(
                    icon: Icons.directions_walk,
                    label: 'Walking',
                    value: walkingEta,
                    iconSize: iconSize,
                    titleSize: titleFontSize,
                    valueSize: valueFontSize,
                    maxWidth: constraints.maxWidth / 3,
                  ),
                  _InfoColumn(
                    icon: Icons.directions_car,
                    label: 'Driving',
                    value: drivingEta,
                    iconSize: iconSize,
                    titleSize: titleFontSize,
                    valueSize: valueFontSize,
                    maxWidth: constraints.maxWidth / 3,
                  ),
                  _InfoColumn(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: distance,
                    iconSize: iconSize,
                    titleSize: titleFontSize,
                    valueSize: valueFontSize,
                    maxWidth: constraints.maxWidth / 3,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              if (isNavigating) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCancelNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.close, size: iconSize * 0.8),
                    label: Text(
                      'Stop Navigation',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddLandmark,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: Icon(Icons.add_location, size: iconSize * 0.8),
                  label: Text(
                    'Add Landmark',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double iconSize;
  final double titleSize;
  final double valueSize;
  final double maxWidth;

  const _InfoColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconSize,
    required this.titleSize,
    required this.valueSize,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: Colors.green, size: iconSize),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: titleSize,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueSize,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
