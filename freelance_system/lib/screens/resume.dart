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
    _fetchResume();
  }

  // Fetch Resume File from Firestore
  Future<void> _fetchResume() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc['resume_file'] != null) {
      setState(() {
        _resumeUrl = userDoc['resume_file'];
      });
    }
  }

  Future<void> _uploadResume() async {
    //Pick up file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);

    if (result == null) return; //User cancelled

    File file = File(result.files.single.path!);

    setState(() {
      _isUploading = true;
    });

    try {
      //Upload to Cloudinary
      String cloudinaryUrl = await _uploadToCloudinary(file);

      //Store to Firestore
      await _saveToFirestore(cloudinaryUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resume uploaded successfully!")),
      );
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

  Future<String> _uploadToCloudinary(File file) async {
    const cloudinaryUploadUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/upload/fl_attachment";
    const uploadPreset = "Resum_files"; // Set this in Cloudinary settings

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..fields['resource_type'] = 'auto' // Ensures correct file type handling
      ..fields['access_mode'] = 'public' // Makes it publicly accessible
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(await response.stream.bytesToString());
      return jsonResponse['secure_url']; // Cloudinary file URL
    } else {
      throw Exception("Failed to upload resume to Cloudinary.");
    }
  }

  Future<void> _saveToFirestore(String fileUrl) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'resume_file': fileUrl,
    });
  }

  // Open PDF File
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
                  SizedBox(
                    width: 10,
                  ),
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
