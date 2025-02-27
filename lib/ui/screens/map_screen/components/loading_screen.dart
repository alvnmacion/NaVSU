import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Preparing your map...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we get everything ready',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
