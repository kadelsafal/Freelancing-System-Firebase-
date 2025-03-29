import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ShowAddPostDialog extends StatefulWidget {
  const ShowAddPostDialog({super.key});

  @override
  State<ShowAddPostDialog> createState() => _ShowAddPostDialogState();
}

class _ShowAddPostDialogState extends State<ShowAddPostDialog> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _statusController = TextEditingController();

  final List<XFile> _uploadedImages = []; // List to hold selected images
  bool _isPosting = false; // State to manage the loading indicator

  // To track loading state of each image
  final Map<int, bool> _imageLoadingStatus =
      {}; // Maps image index to loading state

  /// Upload images to Cloudinary
  Future<List<String?>> uploadImagesToCloudinary(List<XFile> imageFiles) async {
    const cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
    const uploadPreset = "Post Images";
    const folder = "public_posts";
    List<String?> uploadedUrls = [];

    try {
      for (var imageFile in imageFiles) {
        setState(() {
          _imageLoadingStatus[_uploadedImages.indexOf(imageFile)] =
              true; // Start loading indicator
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
          print("Failed to upload image: ${response.reasonPhrase}");
          uploadedUrls.add(null);
        }

        // Simulate a delay to mimic image upload completion
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _imageLoadingStatus[_uploadedImages.indexOf(imageFile)] =
              false; // Stop loading indicator
        });
      }
      return uploadedUrls;
    } catch (e) {
      print("Error uploading images: $e");
      return [];
    }
  }

  /// Save the post to Firestore
  Future<void> savePostToFirestore({
    required List<String?> imageUrls,
  }) async {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    try {
      final timestamp = Timestamp.now();
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;

      final postData = {
        "postId": postId,
        "userId": userProvider.userId,
        "username": userProvider.userName,
        "imageUrls": imageUrls.isNotEmpty ? imageUrls : null,
        "status": _statusController.text,
        "timestamp": timestamp,
        "likes": []
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .set(postData);
      print("Post saved successfully!");
    } catch (e) {
      print("Error saving post to Firestore: $e");
    }
  }

  /// Pick image using ImagePicker
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _uploadedImages.add(image);
          _imageLoadingStatus[_uploadedImages.length - 1] = true;
        });

        // Start uploading the image immediately after selection
        await uploadImagesToCloudinary([image]);
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  /// Remove image from the uploaded list
  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
      _imageLoadingStatus.remove(index);
    });
  }

  /// Handle the "Post" button click
  Future<void> _handlePost() async {
    if (_statusController.text.isEmpty && _uploadedImages.isEmpty) {
      print("Status or an image is required.");
      return;
    }

    setState(() {
      _isPosting = true; // Show loading indicator
    });

    // Upload images to Cloudinary
    List<String?> imageUrls = await uploadImagesToCloudinary(_uploadedImages);

    // Save post to Firestore
    await savePostToFirestore(imageUrls: imageUrls);

    setState(() {
      _isPosting = false; // Hide loading indicator
    });

    Navigator.of(context).pop(); // Close the dialog
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    "Add a Post/Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 10),
              // Status Input Field
              TextField(
                controller: _statusController,
                minLines: 3,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Display uploaded images with vertical scrolling and gap between images
              if (_uploadedImages.isNotEmpty)
                SizedBox(
                  height: 250, // Set a fixed height for the image area
                  child: ListView.builder(
                    itemCount: _uploadedImages.length,
                    itemBuilder: (context, index) {
                      XFile image = _uploadedImages[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0), // Add gap between images
                        child: Container(
                          alignment:
                              Alignment.center, // Center the progress indicator
                          clipBehavior: Clip.none,
                          child: Stack(
                            children: [
                              _imageLoadingStatus[index] == true
                                  ? const CircularProgressIndicator()
                                  : Image.file(
                                      File(image.path),
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.contain,
                                    ),
                              if (_imageLoadingStatus[index] == false)
                                Positioned(
                                  top: 20,
                                  right: -10,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Color.fromARGB(255, 255, 5, 5),
                                      size: 28,
                                    ),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text("Upload Pic"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Post Button
              _isPosting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 10),
                      ),
                      onPressed: _handlePost,
                      child: const Text(
                        "Post",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
