import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/issues_tabs/all_issues.dart';
import 'package:freelance_system/Projects/issues_tabs/solved_issues.dart';

import 'package:freelance_system/providers/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../issues_tabs/unsolved_issues.dart';

class IssuesTab extends StatefulWidget {
  final String projectId;
  final String role;
  const IssuesTab({super.key, required this.projectId, required this.role});

  @override
  _IssuesTabState createState() => _IssuesTabState();
}

class _IssuesTabState extends State<IssuesTab> {
  final TextEditingController _issueController = TextEditingController();
  final List<XFile> _uploadedImages = [];
  List<bool> _imageLoadingStatus = [];
  String _selectedStatus = 'Not Solved';
  int _unsolvedIssuesCount = 0;
  bool _isSubmitting = false; // Add this line to track the loading state

  void _createIssue(String author, String projectId) async {
    String issueText = _issueController.text.trim();
    if (issueText.isEmpty) {
      // Handle empty issue text
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an issue description')),
      );
      return;
    }

    // Get the current timestamp
    Timestamp timestamp = Timestamp.now();

    // Set the submitting state to true to show the loading indicator
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload images first and get URLs
      List<String?> uploadedUrls =
          await uploadImagesToCloudinary(_uploadedImages);

      // Create a new issue in Firestore
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('issues')
          .add({
        'author': author, // Use current logged-in user's name
        'issueText': issueText,
        'status': _selectedStatus,
        'role': widget.role,
        'timestamp': timestamp,
        'imageUrls': uploadedUrls, // Store image URLs in Firestore
      });

      // Issue creation successful, reset form state
      setState(() {
        _uploadedImages.clear();
        _imageLoadingStatus.clear(); // Clear image loading status as well
        _isSubmitting = false; // Reset the submitting state after submission
      });

      // Clear the text field
      _issueController.clear();
    } catch (error) {
      // Handle error during Firestore submission
      setState(() {
        _isSubmitting = false; // Reset the submitting state on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error creating issue. Please try again.')),
      );
    }
  }

  // Function to upload images to Cloudinary
  Future<List<String?>> uploadImagesToCloudinary(List<XFile> imageFiles) async {
    const cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
    const uploadPreset = "Post Images";
    const folder = "public_posts";
    List<String?> uploadedUrls = [];

    try {
      for (var imageFile in imageFiles) {
        setState(() {
          _imageLoadingStatus.add(true); // Start loading indicator
        });

        var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
        request.fields['upload_preset'] = uploadPreset;
        request.fields['folder'] = folder;
        request.files
            .add(await http.MultipartFile.fromPath('file', imageFile.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseBody);
          uploadedUrls.add(jsonResponse['secure_url']);
        } else {
          uploadedUrls.add(null);
        }

        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _imageLoadingStatus.removeAt(
              _uploadedImages.indexOf(imageFile)); // Stop loading indicator
        });
      }
      return uploadedUrls;
    } catch (e) {
      print("Error uploading images: $e");
      return [];
    }
  }

  // Function to pick images using the image picker
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null &&
        pickedFiles.length + _uploadedImages.length <= 3) {
      setState(() {
        _uploadedImages.addAll(pickedFiles);
        _imageLoadingStatus
            .addAll(List.generate(pickedFiles.length, (index) => false));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 3 images')),
      );
    }
  }

  // Function to delete an image
  void _deleteImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
      _imageLoadingStatus.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;
    String projectId = widget.projectId;

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All Issues'),
                Tab(text: 'Solved'),
                Tab(text: 'Unsolved'),
              ],
            ),
            const SizedBox(height: 10),

            // Wrap the TabBarView with an Expanded widget
            Expanded(
              child: TabBarView(
                children: [
                  AllIssues(
                    projectId: projectId,
                    role: widget.role,
                  ),
                  SolvedIssues(
                    projectId: projectId,
                    role: widget.role,
                  ),
                  UnsolvedIssues(
                    projectId: projectId,
                    role: widget.role,
                  ),
                ],
              ),
            ),

            // Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Image Previews
                _uploadedImages.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        children: _uploadedImages.map((imageFile) {
                          int index = _uploadedImages.indexOf(imageFile);
                          return Stack(
                            children: [
                              Image.file(
                                File(imageFile.path),
                                width: 100,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteImage(index),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      )
                    : Container(),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: _issueController,
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: 'Describe the issue',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _uploadedImages.isEmpty
                              ? Icons.image
                              : Icons.add_a_photo_outlined,
                        ),
                        onPressed: _pickImages,
                      )),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null // Disable the button when submitting
                      : () {
                          _createIssue(currentName, projectId); // Use projectId
                        },
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Color.fromARGB(255, 95, 72, 181),
                        ) // Show the loading indicator when submitting
                      : const Text('Submit Issue'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
