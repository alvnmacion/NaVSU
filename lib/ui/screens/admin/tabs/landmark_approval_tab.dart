import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import 'package:navsu/ui/dialog/admin_dialogs/admin_action_dialogs.dart';

class LandmarkApprovalTab extends StatefulWidget {
  const LandmarkApprovalTab({super.key});

  @override
  State<LandmarkApprovalTab> createState() => _LandmarkApprovalTabState();
}

// ... Copy the entire _LandmarkApprovalTabState class here ...
class _LandmarkApprovalTabState extends State<LandmarkApprovalTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('landmarks')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        return _buildLandmarksList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildLandmarksList(List<QueryDocumentSnapshot> landmarks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: landmarks.length,
      itemBuilder: (context, index) {
        final landmark = landmarks[index].data() as Map<String, dynamic>;
        final status = landmark['status'] ?? 'pending';
        final GeoPoint location = landmark['location'] as GeoPoint;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(location.latitude, location.longitude),
                          initialZoom: 18.49,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(location.latitude, location.longitude),
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.circle_sharp,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      landmark['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      landmark['description'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(status),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionButton(
                                'Approve',
                                Colors.green,
                                () => _updateStatus(context, landmarks[index], 'approved'),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                'Reject',
                                Colors.red,
                                () => _updateStatus(context, landmarks[index], 'rejected'),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                'Delete',
                                Colors.grey,
                                () => _deleteLandmark(context, landmarks[index]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'pending': Colors.orange,
      'approved': Colors.green,
      'rejected': Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[status] ?? Colors.grey),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: colors[status],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color),
        ),
      ),
      child: Text(label),
    );
  }

  Future<void> _updateStatus(BuildContext context, DocumentSnapshot landmark, String status) async {
    final data = landmark.data() as Map<String, dynamic>;
    final confirmed = await AdminActionDialogs.showLandmarkStatusConfirmation(
      context,
      status,
      data['name'],
    );
    
    if (confirmed) {
      await landmark.reference.update({'status': status});
    }
  }

  Future<void> _deleteLandmark(BuildContext context, DocumentSnapshot landmark) async {
    final data = landmark.data() as Map<String, dynamic>;
    final confirmed = await AdminActionDialogs.showLandmarkStatusConfirmation(
      context,
      'delete',
      data['name'],
    );
    
    if (confirmed) {
      await landmark.reference.delete();
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }
}

