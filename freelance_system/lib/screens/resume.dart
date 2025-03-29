import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freelance_system/resume/buildresume.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _isUploading = false;
  String? _resumeUrl;
  String? _resumeReview;
  double _score = 0.0;
  Map<String, dynamic>? _entities;

  @override
  void initState() {
    super.initState();
    _fetchResume();
    _loadResumeReviewFromLocal();
  }

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
        print("Fetched resume URL: $_resumeUrl");
      }
    } catch (e) {
      print("Error fetching resume: $e");
    }
  }

  Future<void> _loadResumeReviewFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _resumeReview = prefs.getString('resume_review');
      _score = prefs.getDouble('resume_score') ?? 0.0;
      String? entitiesJson = prefs.getString('resume_entities');
      if (entitiesJson != null) {
        _entities = jsonDecode(entitiesJson);
      }
    });
  }

  Future<void> _saveResumeReviewToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_review', _resumeReview ?? '');
    await prefs.setDouble('resume_score', _score);
    await prefs.setString('resume_entities', jsonEncode(_entities ?? {}));
  }

  Future<File?> _uploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null) return null;
    File file = File(result.files.single.path!);
    setState(() => _isUploading = true);
    try {
      String cloudinaryUrl = await _uploadToCloudinary(file);
      await _saveToFirestore(cloudinaryUrl);
      setState(() => _resumeUrl = cloudinaryUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resume uploaded successfully!")),
      );
      return file;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
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
      throw Exception("Failed to upload resume.");
    }
  }

  Future<void> _saveToFirestore(String fileUrl) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'resume_file': fileUrl},
      SetOptions(merge: true),
    );
  }

  Future<void> uploadResumeForReview(File file) async {
    var uri = Uri.parse("http://192.168.1.25:8000/process_resume/");
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        setState(() {
          _resumeReview = jsonData['review'];
          _score = jsonData['score'];
          _entities = jsonData['entities'];
        });
        await _saveResumeReviewToLocal();
      }
    } catch (e) {
      print("Error connecting to FastAPI: $e");
    }
  }

  Future<void> _openPdf(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open PDF");
    }
  }

  Future<void> _openEditEntitiesDialog() async {
    Map<String, TextEditingController> controllers = {};

    // Initialize controllers for each entity
    _entities?.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.join(", "));
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Entities"),
          content: SingleChildScrollView(
            child: Column(
              children: _entities!.keys.map((key) {
                return TextField(
                  controller: controllers[key],
                  decoration: InputDecoration(labelText: key),
                  maxLines: 2,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Update entities with edited values
                Map<String, List<String>> updatedEntities = {};
                _entities!.forEach((key, value) {
                  updatedEntities[key] = controllers[key]!.text.split(", ");
                });

                // Save updated entities to Firestore
                String userId = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .set(
                  {'resume_entities': updatedEntities},
                  SetOptions(merge: true),
                );

                setState(() {
                  _entities = updatedEntities;
                });

                Navigator.pop(context);
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resume Upload and Review"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload and Build Resume Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            File? file = await _uploadResume();
                            if (file != null) {
                              uploadResumeForReview(file);
                            }
                          },
                    child: _isUploading
                        ? CircularProgressIndicator(color: Colors.deepPurple)
                        : Row(
                            children: [
                              Text("Upload Resume"),
                              SizedBox(width: 5),
                              Icon(Icons.upload,
                                  color: Colors.deepPurple, size: 20),
                            ],
                          ),
                  ),
                ),
                SizedBox(width: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BuildResume()),
                      );
                    },
                    child: Row(
                      children: [
                        Text("Build Resume"),
                        SizedBox(width: 3),
                        Icon(Icons.build, color: Colors.deepPurple, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Display Resume Review Score
            if (_resumeReview != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Resume Score: $_score/10",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // Display Review Content
                  Text(
                    "Review:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  ..._resumeReview!.trim().split("\n").map((line) => Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text(
                          line.trim(),
                          style: TextStyle(fontSize: 16),
                        ),
                      )),

                  SizedBox(height: 20),

                  // Display Entities Section
                  if (_entities != null) ...[
                    Text(
                      "Extracted Entities:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _entities!.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${entry.key}:", // Entity Title
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            ...List.generate(entry.value.length, (index) {
                              return Padding(
                                padding: EdgeInsets.only(left: 15, top: 3),
                                child: Text(
                                  "- ${entry.value[index]}", // Entity Value
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            }),
                            SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),

            SizedBox(height: 20),

            // Show Resume File if Available
            if (_resumeUrl != null)
              ListTile(
                leading:
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                title: Text("View Uploaded Resume"),
                subtitle: Text("Tap to open"),
                onTap: () => _openPdf(_resumeUrl!),
              )
            else
              Text("No resume uploaded yet."),

            // Save Details Button
            if (_entities != null)
              Center(
                child: ElevatedButton(
                  onPressed: _openEditEntitiesDialog,
                  child: Text("Save Details"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
