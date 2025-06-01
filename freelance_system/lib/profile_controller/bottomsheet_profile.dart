import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BottomsheetProfile extends StatefulWidget {
  const BottomsheetProfile({super.key});

  @override
  State<BottomsheetProfile> createState() => _BottomsheetProfileState();
}

class _BottomsheetProfileState extends State<BottomsheetProfile> {
  var editForm = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  var db = FirebaseFirestore.instance;

  @override
  void initState() {
    _nameController.text =
        Provider.of<Userprovider>(context, listen: false).userName;
    _phoneController.text =
        Provider.of<Userprovider>(context, listen: false).userphn;
    super.initState();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image. Please try again.")),
      );
    }
  }

  Future<String> _uploadToCloudinary(File file) async {
    const cloudinaryUploadUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/upload";
    const uploadPreset = "Resum_files";
    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(await response.stream.bytesToString());
      return jsonResponse['secure_url'];
    } else {
      throw Exception("Failed to upload image.");
    }
  }

  void updateData() async {
    try {
      setState(() => _isUploading = true);

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadToCloudinary(_imageFile!);
      }

      // Update user profile in "users" collection
      Map<String, dynamic> userUpdate = {
        "Full Name": _nameController.text,
        "Phone Number": _phoneController.text,
      };

      if (imageUrl != null) {
        userUpdate["profile_image"] = imageUrl;
      }

      await db
          .collection("users")
          .doc(Provider.of<Userprovider>(context, listen: false).userId)
          .update(userUpdate);

      // Update username in "posts" collection for all posts by the user
      QuerySnapshot postsSnapshot = await db
          .collection("posts")
          .where("userId",
              isEqualTo:
                  Provider.of<Userprovider>(context, listen: false).userId)
          .get();

      for (var doc in postsSnapshot.docs) {
        await db.collection("posts").doc(doc.id).update({
          "username": _nameController.text,
        });
      }

      // Refresh user details in the provider
      await Provider.of<Userprovider>(context, listen: false).getUserDetails();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Close the bottom sheet and refresh the profile screen
      Navigator.pop(context, true); // Pass true to indicate successful update
    } catch (e) {
      print("Error updating data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    return SizedBox(
      width: double.infinity,
      height: 450,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: editForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (editForm.currentState!.validate()) {
                        updateData();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade700,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (userProvider.profileimage?.isNotEmpty ?? false)
                                ? NetworkImage(userProvider.profileimage!)
                                : null,
                        child: (_imageFile == null &&
                                (userProvider.profileimage?.isEmpty ?? true))
                            ? Text(
                                userProvider.userName.isNotEmpty
                                    ? userProvider.userName[0]
                                    : "?",
                                style: TextStyle(
                                  fontSize: 48,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Name cannot be Empty";
                  }
                  return null;
                },
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Phone Number Cant be empty";
                  }
                  return null;
                },
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
              ),
              if (_isUploading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.blue.shade700),
                        SizedBox(height: 8),
                        Text(
                          "Updating Profile...",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
