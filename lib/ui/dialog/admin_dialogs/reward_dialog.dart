import 'package:flutter/material.dart';
import 'dart:ui';

// Convert to StatefulWidget for better control
class RewardDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPoints;
  final String? initialQuantity;
  final String? initialPhotoUrl;
  final String? initialLocation; // Add this field
  final Function(String name, int points, int quantity, String photoUrl, String location) onSave; // Update callback signature
  final String title;
  final String submitText;

  const RewardDialog({
    Key? key,
    this.initialName,
    this.initialPoints,
    this.initialQuantity,
    this.initialPhotoUrl,
    this.initialLocation, // Add this parameter
    required this.onSave,
    required this.title,
    required this.submitText,
  }) : super(key: key);

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  late TextEditingController nameController;
  late TextEditingController pointsController;
  late TextEditingController quantityController;
  late TextEditingController photoUrlController;
  late TextEditingController locationController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    pointsController = TextEditingController(text: widget.initialPoints);
    quantityController = TextEditingController(text: widget.initialQuantity);
    photoUrlController = TextEditingController(text: widget.initialPhotoUrl);
    locationController = TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    nameController.dispose();
    pointsController.dispose();
    quantityController.dispose();
    photoUrlController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate sensible dimensions based on screen size
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.85 > 500 ? 500.0 : screenSize.width * 0.85;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Backdrop blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          
          // Dialog content - use SingleChildScrollView directly
          Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Fixed header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.initialName == null ? Icons.add_circle : Icons.edit,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable form content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormField(
                              controller: nameController,
                              label: 'Name',
                              validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildFormField(
                              controller: pointsController,
                              label: 'Points Required',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Points are required';
                                if (int.tryParse(value!) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            _buildFormField(
                              controller: quantityController,
                              label: 'Quantity Available',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Quantity is required';
                                if (int.tryParse(value!) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            _buildFormField(
                              controller: locationController,
                              label: 'Claim Location',
                              hint: 'e.g. Admin Office',
                            ),
                            const SizedBox(height: 16),
                            
                            _buildFormField(
                              controller: photoUrlController,
                              label: 'Photo URL',
                              validator: (value) => value?.isEmpty ?? true ? 'Photo URL is required' : null,
                            ),
                            
                            // Add extra space at bottom of scrollable content
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Fixed button area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          side: BorderSide(color: Colors.green.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(widget.submitText, style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _submitForm() {
    if (formKey.currentState!.validate()) {
      // Parse values safely
      final points = int.tryParse(pointsController.text) ?? 0;
      final quantity = int.tryParse(quantityController.text) ?? 0;
      
      widget.onSave(
        nameController.text.trim(),
        points,
        quantity,
        photoUrlController.text.trim(),
        locationController.text.trim(),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.green.shade700),
        // Add focused color styles
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Change the floating label color when focused
        floatingLabelStyle: TextStyle(color: Colors.green.shade700),
      ),
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      // Add a green cursor color
      cursorColor: Colors.green.shade700,
    );
  }
}
