import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import 'package:navsu/ui/dialog/add_landmark_confirmation_dialog.dart';

class AddLandmarkDialog extends StatefulWidget {
  final LatLng initialLocation;
  final Function(Map<String, dynamic>) onLandmarkAdded;

  const AddLandmarkDialog({
    super.key,
    required this.initialLocation,
    required this.onLandmarkAdded,
  });

  @override
  State<AddLandmarkDialog> createState() => _AddLandmarkDialogState();
}

class _AddLandmarkDialogState extends State<AddLandmarkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late MapController _mapController;
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _saveLandmark() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog before saving
    final bool? shouldSave = await showDialog(
      context: context,
      builder: (context) => AddLandmarkConfirmationDialog(
        landmarkName: _nameController.text,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (shouldSave != true) return;

    try {
      final landmark = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'location': GeoPoint(_selectedLocation.latitude, _selectedLocation.longitude),
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('landmarks').add(landmark);
      widget.onLandmarkAdded(landmark);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving landmark: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final mapHeight = screenSize.height * 0.25; // 25% of screen height

    return Dialog(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SingleChildScrollView( // Added ScrollView for smaller screens
          child: Container(
            padding: const EdgeInsets.all(24),
            width: screenSize.width * 0.9, // 90% of screen width
            constraints: BoxConstraints(
              maxWidth: 600, // Maximum width
              maxHeight: screenSize.height * 0.8, // Maximum 80% of screen height
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Landmark',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.green.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.green.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.green.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.green.shade400),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.green.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.green.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.green.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.green.shade400),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: mapHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 18.49,
                              minZoom: 12.0, // Added minimum zoom restriction
                              maxZoom: 18.49, // Added maximum zoom restriction
                              onTap: (tapPosition, point) {
                                setState(() => _selectedLocation = point);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 40,
                                    height: 40,
                                    point: _selectedLocation,
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveLandmark,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
