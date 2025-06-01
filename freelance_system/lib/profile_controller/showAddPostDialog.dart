import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ShowAddPostDialog extends StatefulWidget {
  const ShowAddPostDialog({super.key});

  @override
  State<ShowAddPostDialog> createState() => _ShowAddPostDialogState();
}

class _ShowAddPostDialogState extends State<ShowAddPostDialog> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;

  final List<XFile> _uploadedImages = []; // List to hold selected images
  bool _isPosting = false; // State to manage the loading indicator

  // To track loading state of each image
  final Map<int, bool> _imageLoadingStatus =
      {}; // Maps image index to loading state

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

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
        "status": _postController.text,
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
    if (_postController.text.isEmpty && _uploadedImages.isEmpty) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Create Post",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.blue),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: Colors.blue.shade100),
              SizedBox(height: 15),
              // Status Input Field
              TextField(
                controller: _postController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
              ),
              SizedBox(height: 15),
              // Display uploaded images
              if (_uploadedImages.isNotEmpty)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: ListView.builder(
                    itemCount: _uploadedImages.length,
                    itemBuilder: (context, index) {
                      XFile image = _uploadedImages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          child: Stack(
                            children: [
                              _imageLoadingStatus[index] == true
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(image.path),
                                        width: double.infinity,
                                        height: 300,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                              if (_imageLoadingStatus[index] == false)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 15),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.photo, color: Colors.white),
                    label: Text("Add Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  _isPosting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _handlePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Post",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
