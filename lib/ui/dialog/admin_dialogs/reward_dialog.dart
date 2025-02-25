import 'package:flutter/material.dart';
import 'dart:ui';

class RewardDialog extends StatelessWidget {
  final String? initialName;
  final String? initialPoints;
  final String? initialQuantity;
  final String? initialPhotoUrl;
  final Function(String name, int points, int quantity, String photoUrl) onSave;
  final String title;
  final String submitText;

  const RewardDialog({
    Key? key,
    this.initialName,
    this.initialPoints,
    this.initialQuantity,
    this.initialPhotoUrl,
    required this.onSave,
    required this.title,
    required this.submitText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: initialName);
    final pointsController = TextEditingController(text: initialPoints);
    final quantityController = TextEditingController(text: initialQuantity);
    final photoUrlController = TextEditingController(text: initialPhotoUrl);
    final formKey = GlobalKey<FormState>();

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black12,
          ),
        ),
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: nameController,
                    label: 'Name',
                    validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
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
                  _buildTextField(
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
                  _buildTextField(
                    controller: photoUrlController,
                    label: 'Photo URL',
                    validator: (value) => value?.isEmpty ?? true ? 'Photo URL is required' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            onSave(
                              nameController.text,
                              int.parse(pointsController.text),
                              int.parse(quantityController.text),
                              photoUrlController.text,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(submitText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
