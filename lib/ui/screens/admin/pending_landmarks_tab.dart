import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:navsu/backend/backend_service.dart';

class PendingLandmarksTab extends StatefulWidget {
  const PendingLandmarksTab({super.key});

  @override
  State<PendingLandmarksTab> createState() => _PendingLandmarksTabState();
}

class _PendingLandmarksTabState extends State<PendingLandmarksTab> {
  final Backend _backend = Backend();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingLandmarks = [];

  @override
  void initState() {
    super.initState();
    _loadPendingLandmarks();
  }

  Future<void> _loadPendingLandmarks() async {
    setState(() => _isLoading = true);
    
    try {
      final landmarks = await _backend.getPendingLandmarks();
      setState(() {
        _pendingLandmarks = landmarks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading pending landmarks: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLandmarkStatus(String landmarkId, String status) async {
    try {
      final success = await _backend.updateLandmarkStatus(landmarkId, status);
      
      if (success) {
        // Reload data
        await _loadPendingLandmarks();
        
        // Show success message
        _showSnackBar('Landmark updated successfully', Colors.green);
      } else {
        _showSnackBar('Failed to update landmark', Colors.red);
      }
    } catch (e) {
      debugPrint('Error updating landmark: $e');
      _showSnackBar('Error updating landmark status', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingLandmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pending landmarks',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingLandmarks,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingLandmarks.length,
        itemBuilder: (context, index) {
          final landmark = _pendingLandmarks[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Landmark image
                if (landmark['photoUrl'] != null)
                  SizedBox(
                    width: double.infinity,
                    height: 160,
                    child: CachedNetworkImage(
                      imageUrl: landmark['photoUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                
                // Landmark details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        landmark['name'] ?? 'Unnamed Landmark',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        landmark['description'] ?? 'No description provided',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      if (landmark['created_at'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Submitted: ${(landmark['created_at'] as Timestamp).toDate().toString().substring(0, 16)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Reject button
                      OutlinedButton.icon(
                        onPressed: () {
                          _updateLandmarkStatus(landmark['id'], 'rejected');
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Approve button
                      ElevatedButton.icon(
                        onPressed: () {
                          _updateLandmarkStatus(landmark['id'], 'approved');
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
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
