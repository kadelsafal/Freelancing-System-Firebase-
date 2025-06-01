import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:freelance_system/screens/splash_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class IntroSliderScreen extends StatefulWidget {
  final String userId;
  const IntroSliderScreen({super.key, required this.userId});

  @override
  State<IntroSliderScreen> createState() => _IntroSliderScreenState();
}

class _IntroSliderScreenState extends State<IntroSliderScreen> {
  int _currentStep = 0;
  File? _profileImage;
  String? _resumePath;
  String? _resumeFileName;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingResume = false;

  bool _isUploadingImage = false;

//Upload Resume File to Cloudinary
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
      throw Exception("Failed to upload resume.");
    }
  }

  /// Upload images to Cloudinary
  Future<String?> uploadImageToCloudinary(XFile imageFile) async {
    const cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
    const uploadPreset = "Post Images";
    const folder = "public_posts";

    setState(() {
      _isUploadingImage =
          true; // Set loading status to true when uploading starts
    });

    try {
      // No need for a loop, just handle a single image
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        setState(() {
          _isUploadingImage =
              false; // Set loading status to false after uploading
        });
        return jsonResponse[
            'secure_url']; // Return the URL of the uploaded image
      } else {
        print("Failed to upload image: ${response.reasonPhrase}");
        setState(() {
          _isUploadingImage = false; // Set loading status to false on failure
        });
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      setState(() {
        _isUploadingImage = false; // Set loading status to false on error
      });
      return null;
    }
  }

  Future<void> saveProfileImage(String imageUrl) async {
    if (widget.userId == null || widget.userId.trim().isEmpty) {
      print("Invalid userId. Cannot save to Firestore.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'profile_image': imageUrl});
      print("Profile image saved successfully!");
    } catch (e) {
      print("Error saving profile image to Firestore: $e");
    }
  }

  Future<void> saveResumeFile(String fileUrl) async {
    if (widget.userId == null || widget.userId.trim().isEmpty) {
      print("Invalid userId. Cannot save to Firestore.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'resume_file': fileUrl});
      print("Profile image saved successfully!");
    } catch (e) {
      print("Error saving profile image to Firestore: $e");
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      // Navigate to splash or dashboard after final step
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);
        });
      }

      //Upload the image to Cloudinary
      String? imageUrl = await uploadImageToCloudinary(pickedImage!);

      if (imageUrl != null) {
        // Save the image URL in Firestore under the user's document
        saveProfileImage(imageUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _resumePath = result.files.single.path;
          _resumeFileName = result.files.single.name;
          _isUploadingResume = true; // Show loading indicator
        });

        File file = File(result.files.single.path!);

        String fileUrl = await _uploadToCloudinary(file);

        await saveResumeFile(fileUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    } finally {
      setState(() {
        _isUploadingResume = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildProfileImageStep(),
      _buildResumeStep(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: steps[_currentStep],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 30.0,
            bottom: 20.0,
            left: 24.0,
            right: 24.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Complete Your Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 19, 119, 249),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Step ${_currentStep + 1} of 2",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 2,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 37, 121, 211)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          top: 36,
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            },
            child: const Text(
              "Skip",
              style: TextStyle(
                color: Color.fromARGB(255, 45, 129, 198),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Upload Profile Picture",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 59, 100, 205),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Please add a profile picture so others can recognize you",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 40),

        /// Image Picker Area
        GestureDetector(
          onTap: _isUploadingImage ? null : _pickImage,
          child: Center(
            child: _isUploadingImage
                ? const SizedBox(
                    width: 180,
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _profileImage == null
                    ? Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromARGB(255, 162, 198, 253),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 80,
                              color: Color.fromARGB(255, 109, 152, 251),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Tap to select",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 92, 139, 211),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(255, 163, 209, 255),
                                width: 3,
                              ),
                              image: DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 129, 185, 242),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
          ),
        ),

        const SizedBox(height: 30),

        /// Upload Button
        ElevatedButton.icon(
          onPressed: _isUploadingImage ? null : _pickImage,
          icon: _isUploadingImage
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.camera_alt, color: Colors.white),
          label: Text(
            _isUploadingImage
                ? "Uploading..."
                : (_profileImage == null ? "Choose Image" : "Change Image"),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 89, 167, 251),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Upload Resume",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 59, 125, 238),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Add your resume to help potential clients learn about your skills",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 40),

        // File container with loading indicator
        GestureDetector(
          onTap: _isUploadingResume ? null : _pickResume,
          child: Container(
            width: 200,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _resumePath != null
                    ? const Color.fromARGB(255, 82, 164, 227)
                    : Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _isUploadingResume
                ? const Center(child: CircularProgressIndicator())
                : _resumePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            size: 70,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No file selected",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getFileIcon(_resumeFileName ?? ""),
                            size: 70,
                            color: const Color.fromARGB(255, 63, 129, 199),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _resumeFileName ?? "File selected",
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 58, 127, 183),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),

        const SizedBox(height: 30),

        // Upload/resume button with loading state
        ElevatedButton.icon(
          onPressed: _isUploadingResume ? null : _pickResume,
          icon: _isUploadingResume
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.upload_file, color: Colors.white),
          label: Text(_resumePath == null
              ? (_isUploadingResume ? "Uploading..." : "Choose File")
              : (_isUploadingResume ? "Uploading..." : "Change File")),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 89, 167, 251),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.blue,
              ),
              label: const Text("Back"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 100),
          ElevatedButton(
            onPressed: () {
              if (_currentStep == 0 && _profileImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please upload a profile picture'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_currentStep == 1 && _resumePath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please upload your resume'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 89, 167, 251),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Text(_currentStep < 1 ? "Next" : "Finish"),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      return Icons.article;
    } else {
      return Icons.insert_drive_file;
    }
  }
}
