import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/resume/buildresume.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _isUploading = false;
  String? _resumeUrl;

  @override
  void initState() {
    super.initState();
    _fetchResume(); // Fetch the resume when the screen is initialized
  }

  // Fetch Resume File from Firestore
  Future<void> _fetchResume() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['resume_file'] != null) {
        setState(() {
          _resumeUrl = userDoc['resume_file'];
        });
        print(
            "Fetched resume URL: $_resumeUrl"); // Display fetched URL in console
      } else {
        print("No resume URL found in Firestore.");
      }
    } catch (e) {
      print("Error fetching resume: $e");
    }
  }

  // Upload Resume to Cloudinary and Save to Firestore
  Future<void> _uploadResume() async {
    // Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);

    if (result == null) return; // User canceled the file picker

    File file = File(result.files.single.path!);

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload to Cloudinary
      String cloudinaryUrl = await _uploadToCloudinary(file);

      // Store the URL in Firestore
      await _saveToFirestore(cloudinaryUrl);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resume uploaded successfully!")),
      );

      // Fetch the updated resume URL after saving
      _fetchResume();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Upload the file to Cloudinary and get the file URL
  Future<String> _uploadToCloudinary(File file) async {
    const cloudinaryUploadUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/upload"; // Cloudinary upload URL
    const uploadPreset = "Resum_files"; // Cloudinary upload preset

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..fields['resource_type'] = 'auto' // Ensures correct file type handling
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(await response.stream.bytesToString());
        return jsonResponse['secure_url']; // Cloudinary file URL
      } else {
        // Log the response body and status code if upload fails
        final responseBody = await response.stream.bytesToString();
        print(
            "Cloudinary upload failed: ${response.statusCode} - $responseBody");
        throw Exception("Failed to upload resume to Cloudinary.");
      }
    } catch (e) {
      // Handle any other exceptions
      print("Error uploading to Cloudinary: $e");
      throw Exception("Failed to upload resume to Cloudinary.");
    }
  }

  // Save the Cloudinary URL to Firestore for the current user
  Future<void> _saveToFirestore(String fileUrl) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'resume_file': fileUrl,
      });

      print("Resume URL saved to Firestore: $fileUrl");
    } catch (e) {
      print("Error saving resume URL to Firestore: $e");
      throw Exception("Failed to save resume URL to Firestore.");
    }
  }

  // Open the PDF file in an external application
  Future<void> _openPdf(String url) async {
    final Uri pdfUri = Uri.parse(url);

    if (!await launchUrl(pdfUri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open PDF");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resume"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 46, 0, 106),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: _isUploading ? null : _uploadResume,
                    child: _isUploading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                            children: [
                              Text("Upload Resume"),
                              SizedBox(width: 5),
                              Icon(Icons.upload, color: Colors.white, size: 25),
                            ],
                          ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 46, 0, 106),
                        foregroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BuildResume()));
                      },
                      child: Row(
                        children: [
                          Text("Build Resume"),
                          SizedBox(width: 5),
                          Icon(
                            Icons.build,
                            color: Colors.white,
                            size: 25,
                          ),
                        ],
                      )),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Show Resume File if Available
            _resumeUrl != null
                ? Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf,
                          color: Colors.red, size: 40),
                      title: Text("View Uploaded Resume",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text("Tap to open",
                          style: TextStyle(color: Colors.grey[600])),
                      onTap: () => _openPdf(_resumeUrl!),
                    ),
                  )
                : Text("No resume uploaded yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
