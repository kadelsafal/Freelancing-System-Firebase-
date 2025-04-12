import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'issues_service.dart';

class IssuesForm extends StatefulWidget {
  final String projectId;
  final String role;

  const IssuesForm({super.key, required this.projectId, required this.role});

  @override
  State<IssuesForm> createState() => _IssuesFormState();
}

class _IssuesFormState extends State<IssuesForm> {
  final TextEditingController _controller = TextEditingController();
  final List<XFile> _images = [];
  bool _isSubmitting = false;

  Future<void> _submitIssue() async {
    final userName = Provider.of<Userprovider>(context, listen: false).userName;
    final issueText = _controller.text.trim();

    if (issueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an issue description')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final urls = await uploadImagesToCloudinary(_images);
    await createIssue(userName, widget.projectId, widget.role, issueText, urls);

    setState(() {
      _images.clear();
      _controller.clear();
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _images
                .asMap()
                .entries
                .map((entry) => Stack(
                      children: [
                        Image.file(
                          File(entry.value.path),
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => _images.removeAt(entry.key));
                            },
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Describe the issue',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(42),
              borderSide: const BorderSide(
                color: Colors.deepPurple, // Deep purple border color
                width: 4.0, // Thickness of the border
                style: BorderStyle.solid, // Solid border style
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(42),
              borderSide: const BorderSide(
                color: Colors.deepPurple,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(42),
              borderSide: const BorderSide(
                color: Colors.deepPurple,
                width: 2.0,
              ),
            ),
            prefixIcon: _images.length < 1
                ? IconButton(
                    icon: const Icon(
                      Icons.image,
                      size: 30,
                    ),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickMultiImage();
                      if (picked.length + _images.length > 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Max 3 images')),
                        );
                      } else {
                        setState(() => _images.addAll(picked));
                      }
                    },
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.add_a_photo,
                      size: 30,
                    ),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickMultiImage();
                      if (picked.length + _images.length > 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Max 3 images')),
                        );
                      } else {
                        setState(() => _images.addAll(picked));
                      }
                    },
                  ),
            suffixIcon: _isSubmitting
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.blue,
                      size: 35,
                    ),
                    onPressed: _submitIssue,
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
