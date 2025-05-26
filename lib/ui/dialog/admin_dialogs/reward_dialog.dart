import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

// Convert to StatefulWidget for better control
class RewardDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPoints;
  final String? initialQuantity;
  final String? initialPhotoUrl;
  final String? initialLocation;
  final Function(String name, int points, int quantity, String photoData, String location) onSave;
  final String title;
  final String submitText;

  const RewardDialog({
    super.key,
    this.initialName,
    this.initialPoints,
    this.initialQuantity,
    this.initialPhotoUrl,
    this.initialLocation,
    required this.onSave,
    required this.title,
    required this.submitText,
  });

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  late TextEditingController nameController;
  late TextEditingController pointsController;
  late TextEditingController quantityController;
  late TextEditingController locationController;
  final formKey = GlobalKey<FormState>();
  
  Uint8List? _imageBytes;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    pointsController = TextEditingController(text: widget.initialPoints);
    quantityController = TextEditingController(text: widget.initialQuantity);
    locationController = TextEditingController(text: widget.initialLocation);
    
    // If there's an initial photo URL, try to convert it
    if (widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty) {
      if (widget.initialPhotoUrl!.startsWith('data:image')) {
        try {
          // Extract base64 data and convert to bytes
          final base64String = widget.initialPhotoUrl!.split(',')[1];
          _imageBase64 = widget.initialPhotoUrl;
          _imageBytes = base64Decode(base64String);
        } catch (e) {
          debugPrint('Error loading initial image: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    pointsController.dispose();
    quantityController.dispose();
    locationController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      // Read image as bytes
      final bytes = await image.readAsBytes();
      
      // Convert to base64 for storage
      final base64String = base64Encode(bytes);
      final base64Image = 'data:image/jpeg;base64,$base64String';
      
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Image;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting image')),
      );
    }
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
                              validator: (value) => value?.isEmpty ?? true ? 'Location is required' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildImagePicker(),
                            
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward Image',
          style: TextStyle(
            fontSize: 16,
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No image selected',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
        ),
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(
              Icons.add_photo_alternate,
              color: Colors.green.shade700,
            ),
            label: Text(
              _imageBytes == null ? 'Select Image' : 'Change Image',
              style: TextStyle(color: Colors.green.shade700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: Colors.green.shade700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        if (_imageBytes == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'An image is required',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }
  
  void _submitForm() {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }
    
    if (formKey.currentState!.validate()) {
      // Parse values safely
      final points = int.tryParse(pointsController.text) ?? 0;
      final quantity = int.tryParse(quantityController.text) ?? 0;
      
      widget.onSave(
        nameController.text.trim(),
        points,
        quantity,
        _imageBase64!, // Send the base64 encoded image
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        floatingLabelStyle: TextStyle(color: Colors.green.shade700),
      ),
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      cursorColor: Colors.green.shade700,
    );
  }
}
