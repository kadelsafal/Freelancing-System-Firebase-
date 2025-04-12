import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freelance_system/Projects/tabs/status/status_service.dart';

class StatusInputWrapper extends StatefulWidget {
  final String projectId;
  final String currentName;
  final String role;

  const StatusInputWrapper({
    super.key,
    required this.projectId,
    required this.currentName,
    required this.role,
  });

  @override
  State<StatusInputWrapper> createState() => _StatusInputWrapperState();
}

class _StatusInputWrapperState extends State<StatusInputWrapper> {
  final TextEditingController controller = TextEditingController();
  final List<XFile> selectedImages = [];
  bool isPosting = false;
  double _maxLines = 2; // Use double.infinity for unlimited lines

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() => selectedImages.addAll(images));
    }
  }

  void deleteImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  Future<void> postUpdate() async {
    if (controller.text.trim().isEmpty && selectedImages.isEmpty) return;
    setState(() => isPosting = true);

    await StatusService.postStatusUpdate(
      projectId: widget.projectId,
      author: widget.currentName,
      role: widget.role,
      text: controller.text.trim(),
      selectedImages: selectedImages,
    );

    controller.clear();
    selectedImages.clear();
    setState(() => isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return StatusInputField(
      controller: controller,
      selectedImages: selectedImages,
      onPickImage: pickImage,
      onPostUpdate: postUpdate,
      onDeleteImage: deleteImage,
      isPosting: isPosting,
      maxLines: _maxLines,
      onMaxLinesChanged: (lines) {
        setState(() {
          _maxLines = lines;
        });
      },
    );
  }
}

class StatusInputField extends StatelessWidget {
  final TextEditingController controller;
  final List<XFile> selectedImages;
  final VoidCallback onPickImage;
  final VoidCallback onPostUpdate;
  final void Function(int) onDeleteImage;
  final bool isPosting;
  final double maxLines; // Change maxLines to double
  final void Function(double)
      onMaxLinesChanged; // Change parameter type to double

  const StatusInputField({
    super.key,
    required this.controller,
    required this.selectedImages,
    required this.onPickImage,
    required this.onPostUpdate,
    required this.onDeleteImage,
    required this.isPosting,
    required this.maxLines,
    required this.onMaxLinesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    children: [
                      Image.file(
                        File(selectedImages[index].path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => onDeleteImage(index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          maxLines: maxLines.toInt(), // Convert to int
          controller: controller,
          onChanged: (text) {
            // Update maxLines if content exceeds 2 lines
            int lineCount = text.split('\n').length;
            if (lineCount > 2 && maxLines == 2) {
              onMaxLinesChanged(
                  double.infinity); // Allow expansion beyond 2 lines
            } else if (lineCount <= 2 && maxLines != 2) {
              onMaxLinesChanged(2); // Reset to 2 lines when content is short
            }
          },
          decoration: InputDecoration(
            labelText: "Post a Status Update",
            hintText: "Write your update here...", // Added hint text
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            prefixIcon: IconButton(
              icon: Icon(
                selectedImages.isEmpty ? Icons.image : Icons.add_a_photo,
              ),
              onPressed: onPickImage,
            ),
            suffixIcon: isPosting
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 5, // Set the desired width
                      height: 10, // Set the desired height
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  ) // Show progress indicator in place of the send icon
                : IconButton(
                    onPressed: isPosting ? null : onPostUpdate,
                    icon: const Icon(Icons.send, color: Colors.blue),
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
