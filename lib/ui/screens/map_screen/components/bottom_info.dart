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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoColumn(
                icon: Icons.directions_walk,
                label: 'Walking',
                value: walkingEta,
              ),
              _InfoColumn(
                icon: Icons.directions_car,
                label: 'Driving',
                value: drivingEta,
              ),
              _InfoColumn(
                icon: Icons.straighten,
                label: 'Distance',
                value: distance,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isNavigating)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCancelNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'Stop Navigation',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (isNavigating) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddLandmark,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_location),
                  label: const Text(
                    'Add Landmark',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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

  const _InfoColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
