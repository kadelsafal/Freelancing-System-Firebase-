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
        _entities = (jsonDecode(entitiesJson) as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
              key, (value as List<dynamic>).map((e) => e.toString()).toList()),
        );
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

    _entities?.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.join(", "));
    });

    showDialog(
      context: context,
      builder: (context) {
        final workedAsList = _entities?["WORKED AS"] ?? [];
        final companiesList = _entities?["COMPANIES WORKED AT"] ?? [];
        final durationList = _entities?["DURATION"] ?? [];
        final skillsList = _entities?["SKILLS"] ?? [];

        final maxLength = [
          workedAsList.length,
          companiesList.length,
          durationList.length
        ].reduce((a, b) => a > b ? a : b);

        List<Map<String, TextEditingController>> workExperienceControllers = [];

        for (int i = 0; i < maxLength; i++) {
          workExperienceControllers.add({
            "workedAs": TextEditingController(
                text: i < workedAsList.length ? workedAsList[i] : ""),
            "company": TextEditingController(
                text: i < companiesList.length ? companiesList[i] : ""),
            "duration": TextEditingController(
                text: i < durationList.length ? durationList[i] : ""),
          });
        }

        if (workExperienceControllers.isEmpty) {
          workExperienceControllers.add({
            "workedAs": TextEditingController(),
            "company": TextEditingController(),
            "duration": TextEditingController(),
          });
        }

        // Check if 'YEARS OF EXPERIENCE' is present, otherwise leave it empty
        TextEditingController yearsOfExperienceController =
            TextEditingController(
          text: (_entities?["YEARS OF EXPERIENCE"] != null &&
                  _entities?["YEARS OF EXPERIENCE"] is List &&
                  (_entities?["YEARS OF EXPERIENCE"] as List).isNotEmpty)
              ? (_entities?["YEARS OF EXPERIENCE"] as List)[0]
              : "",
        );

        TextEditingController skillController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Resume Info"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: yearsOfExperienceController,
                      decoration:
                          InputDecoration(labelText: "Years of Experience"),
                      onChanged: (value) {
                        // Update the years of experience value
                        _entities?["YEARS OF EXPERIENCE"] = [value];
                      },
                    ),
                    SizedBox(height: 20),
                    Text("Work Experience:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ...workExperienceControllers.asMap().entries.map((entry) {
                      int i = entry.key;
                      var map = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Work Experience ${i + 1}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          TextField(
                            controller: map["workedAs"],
                            decoration: InputDecoration(labelText: "Worked As"),
                          ),
                          TextField(
                            controller: map["company"],
                            decoration: InputDecoration(labelText: "Company"),
                          ),
                          TextField(
                            controller: map["duration"],
                            decoration: InputDecoration(labelText: "Duration"),
                          ),
                          SizedBox(height: 15),
                        ],
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          workExperienceControllers.add({
                            "workedAs": TextEditingController(),
                            "company": TextEditingController(),
                            "duration": TextEditingController(),
                          });
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text("Add Work Experience"),
                    ),
                    SizedBox(height: 20),
                    Text("Skills:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: skillsList
                          .map<Widget>((skill) => Chip(
                                label: Text(skill),
                                onDeleted: () {
                                  setState(() {
                                    skillsList.remove(skill);
                                  });
                                },
                                deleteIconColor: Colors.red,
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: skillController,
                      decoration: InputDecoration(labelText: "Add Skill"),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            skillsList.add(value);
                            skillController.clear();
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    ..._entities!.keys.where((key) {
                      final lowerKey = key.toLowerCase();
                      return lowerKey != "worked as" &&
                          lowerKey != "duration" &&
                          lowerKey != "companies worked at" &&
                          lowerKey != "skills" &&
                          lowerKey !=
                              "years of experience"; // Exclude 'years of experience'
                    }).map((key) {
                      controllers.putIfAbsent(
                        key,
                        () => TextEditingController(
                            text: _entities?[key]?.join(", ") ?? ""),
                      );
                      return TextField(
                        controller: controllers[key],
                        decoration: InputDecoration(labelText: key),
                        maxLines: 2,
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Map<String, List<String>> updatedEntities = {};

                    controllers.forEach((key, controller) {
                      updatedEntities[key] = controller.text
                          .split(",")
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                    });

                    updatedEntities["WORKED AS"] = workExperienceControllers
                        .map((e) => e["workedAs"]!.text)
                        .where((text) => text.isNotEmpty)
                        .toList();

                    updatedEntities["COMPANIES WORKED AT"] =
                        workExperienceControllers
                            .map((e) => e["company"]!.text)
                            .where((text) => text.isNotEmpty)
                            .toList();

                    updatedEntities["DURATION"] = workExperienceControllers
                        .map((e) => e["duration"]!.text)
                        .where((text) => text.isNotEmpty)
                        .toList();

                    updatedEntities["SKILLS"] = List<String>.from(skillsList);

                    // Ensure that the 'YEARS OF EXPERIENCE' field is updated
                    updatedEntities["YEARS OF EXPERIENCE"] = [
                      yearsOfExperienceController.text.trim()
                    ];

                    String userId = FirebaseAuth.instance.currentUser!.uid;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .set(
                      {'resume_entities': updatedEntities},
                      SetOptions(merge: true),
                    );

                    // Save updated data to local storage
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                        'resume_entities', jsonEncode(updatedEntities));

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
                              await uploadResumeForReview(file);
                              setState(() {}); // Update UI after upload
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
                        MaterialPageRoute(builder: (context) => BuildResume()),
                      ).then((_) {
                        setState(
                            () {}); // Update UI after returning from BuildResume
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
                              "${entry.key}:",
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
                  onPressed: () async {
                    await _openEditEntitiesDialog();
                    setState(() {}); // Refresh UI after saving details
                  },
                  child: Text("Save Details"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
