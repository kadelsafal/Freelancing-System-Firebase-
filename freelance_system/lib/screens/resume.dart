import 'dart:convert';
import 'dart:io';
import 'package:freelance_system/resume/edit_resume_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freelance_system/resume/buildresume.dart';

class ResumeScreen extends StatefulWidget {
  final String? userId;

  const ResumeScreen({super.key, this.userId});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _isUploading = false;
  String? _resumeUrl;
  String? _resumeReview;
  double _score = 0.0;
  Map<String, List<String>>? _entities;

  late String _currentUserId;
  bool _isCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    _isCurrentUser = widget.userId == null ||
        widget.userId == FirebaseAuth.instance.currentUser!.uid;
    _fetchUserResumeData();
  }

  Future<void> _fetchUserResumeData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          if (userDoc.data() is Map<String, dynamic>) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            _resumeUrl = userData['resume_file'];
            _resumeReview = userData['resume_review'];
            _score = (userData['resume_score'] ?? 0.0).toDouble();

            if (userData['resume_entities'] != null) {
              _entities =
                  (userData['resume_entities'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>).map((e) => e.toString()).toList(),
                ),
              );
            }
          }
        });
        print("Fetched resume data for user: $_currentUserId");
      }
    } catch (e) {
      print("Error fetching resume data: $e");
    }
  }

  Future<void> _saveResumeDataToFirestore() async {
    if (_entities != null) {
      Map<String, dynamic> filteredEntities = Map.from(_entities!);
      filteredEntities.removeWhere((key, value) =>
          key.toLowerCase() == 'name' ||
          key.toLowerCase() == 'email address' ||
          key.toLowerCase() == 'email');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .set({
        'resume_review': _resumeReview,
        'resume_score': _score,
        'resume_entities': filteredEntities,
      }, SetOptions(merge: true));
    }
  }

  Future<File?> _uploadResume() async {
    if (!_isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only upload your own resume")),
      );
      return null;
    }

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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .set(
      {'resume_file': fileUrl},
      SetOptions(merge: true),
    );
  }

  Future<void> uploadResumeForReview(File file) async {
    var uri = Uri.parse("http://192.168.1.98:8000/process_resume/");
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
          _entities = Map<String, dynamic>.from(jsonData['entities'])
              .cast<String, List<String>>();
        });

        Map<String, dynamic> filteredEntities =
            Map<String, dynamic>.from(jsonData['entities']);
        filteredEntities.removeWhere((key, value) =>
            key.toLowerCase() == 'name' ||
            key.toLowerCase() == 'email address' ||
            key.toLowerCase() == 'email');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .update({
          'resume_review': _resumeReview,
          'resume_score': _score,
          'resume_entities': filteredEntities,
        });
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
    if (!_isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only edit your own resume")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return EditResumeDialog(
          entities: _entities!, // Pass entities to the dialog
          currentUserId: _currentUserId, // Pass the current user ID
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCurrentUser ? "My Resume" : "User Resume"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isCurrentUser)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              File? file = await _uploadResume();
                              if (file != null) {
                                await uploadResumeForReview(file);
                                setState(() {});
                              }
                            },
                      child: _isUploading
                          ? CircularProgressIndicator(color: Colors.deepPurple)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
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
                          MaterialPageRoute(
                              builder: (context) => BuildResume()),
                        ).then((_) {
                          _fetchUserResumeData();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text("No data found");
                }

                Map<String, dynamic> userData =
                    snapshot.data!.data() as Map<String, dynamic>;

                _resumeUrl = userData['resume_file'];
                _resumeReview = userData['resume_review'];
                _score = (userData['resume_score'] ?? 0.0).toDouble();

                if (userData['resume_entities'] != null) {
                  _entities =
                      (userData['resume_entities'] as Map<String, dynamic>).map(
                    (key, value) => MapEntry(
                        key,
                        (value as List<dynamic>)
                            .map((e) => e.toString())
                            .toList()),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_resumeReview != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Resume Score: $_score/10",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Review:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          ..._resumeReview!
                              .trim()
                              .split("\n")
                              .map((line) => Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text(
                                      line.trim(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )),
                          SizedBox(height: 20),
                          if (_entities != null) ...[
                            Text(
                              "Extracted Entities:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _entities!.entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${entry.key}:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    ...List.generate(entry.value.length,
                                        (index) {
                                      return Padding(
                                        padding:
                                            EdgeInsets.only(left: 15, top: 3),
                                        child: Text(
                                          "- ${entry.value[index]}",
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
                    if (_resumeUrl != null)
                      ListTile(
                        leading: Icon(Icons.picture_as_pdf,
                            color: Colors.red, size: 40),
                        title: Text("View Uploaded Resume"),
                        subtitle: Text("Tap to open"),
                        onTap: () => _openPdf(_resumeUrl!),
                      )
                    else
                      Text("No resume uploaded yet."),
                    if (_entities != null && _isCurrentUser)
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _openEditEntitiesDialog();
                            setState(() {}); // Refresh UI after saving details
                          },
                          child: Text("Edit Resume Details"),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
