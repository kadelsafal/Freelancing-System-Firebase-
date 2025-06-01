import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'addchapter.dart';
import 'package:google_fonts/google_fonts.dart';

class Addcourse extends StatefulWidget {
  const Addcourse({super.key});

  @override
  State<Addcourse> createState() => _AddcourseState();
}

class _AddcourseState extends State<Addcourse> {
  final _formKey = GlobalKey<FormState>();

  // Cloudinary Credentials
  final String cloudName = "dnebaumu9";
  final String uploadPreset = "Post Images";

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isUploading = false;

  final TextEditingController _benefitController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  File? _posterImage;
  String? _posterUrl;
  bool _isImageUploading = false;

  final List<String> _benefitsList = [];
  final List<String> _skillsList = [];

  String? _selectedCourseType;

  final List<String> _courseTypes = [
    'Web Development',
    'Mobile App Development',
    'Graphic Design & Multimedia',
    'Digital Marketing',
    'Data Science & Machine Learning',
    'Writing & Content Creation',
    'Business & Entrepreneurship',
    'Cybersecurity',
    'Cloud Computing & DevOps',
    'Translation & Language Services',
    'Others'
  ];

  void _addBenefit() {
    final text = _benefitController.text.trim();
    if (text.isNotEmpty && !_benefitsList.contains(text)) {
      setState(() {
        _benefitsList.add(text);
        _benefitController.clear();
      });
    }
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefitsList.removeAt(index);
    });
  }

  void _addSkill() {
    final text = _skillController.text.trim();
    if (text.isNotEmpty && !_skillsList.contains(text)) {
      setState(() {
        _skillsList.add(text);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skillsList.removeAt(index);
    });
  }

  // Upload File to Cloudinary (Image)
  Future<String?> uploadFileToCloudinary(File file) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/upload");
    var request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(responseData);
      return jsonResponse["secure_url"];
    } else {
      print("File upload failed: ${response.statusCode} - $responseData");
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        setState(() {
          _posterImage = imageFile;
          _isImageUploading = true;
        });

        try {
          String? imageUrl = await uploadFileToCloudinary(_posterImage!);

          setState(() {
            _posterUrl = imageUrl;
            _isImageUploading = false;
          });

          if (imageUrl == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Failed to upload image. Please try again.")),
            );
          }
        } catch (e) {
          setState(() => _isImageUploading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to upload image: $e")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick image: $e")),
        );
      }
    }
  }

  Future<File> _resizeImage(File imageFile) async {
    final ImagePicker picker = ImagePicker();
    final XFile? resizedImage = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (resizedImage == null) throw Exception('No image selected');
    return File(resizedImage.path);
  }

  Future<void> _navigateToAddChapters() async {
    if (!_formKey.currentState!.validate() || _selectedCourseType == null) {
      return;
    }

    if (_posterUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a course poster")),
      );
      return;
    }

    setState(() => _isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    final currentUserName =
        Provider.of<Userprovider>(context, listen: false).userName;

    if (user == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    // Generate unique course ID
    String courseId = FirebaseFirestore.instance.collection("courses").doc().id;

    double? price;
    try {
      price = double.parse(_priceController.text.trim());
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid price format.")),
      );
      return;
    }

    // Prepare Firestore data
    Map<String, dynamic> courseData = {
      "courseId": courseId,
      "title": _titleController.text.trim(),
      "description": _descriptionController.text.trim(),
      "userId": user.uid,
      "username": currentUserName.isNotEmpty ? currentUserName : "Unknown",
      "price": price,
      "benefits": _benefitsList,
      "skills": _skillsList,
      "appliedUsers": 0,
      "courseType": _selectedCourseType,
      "posterUrl": _posterUrl,
      "createdAt": FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection("courses")
          .doc(courseId)
          .set(courseData);
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course added successfully!")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddChapter(courseId: courseId)),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add course: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double horizontalPadding = constraints.maxWidth > 700
                      ? (constraints.maxWidth - 600) / 2
                      : 0;
                  return Column(
                    children: [
                      // Blue header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                            left: 24, right: 16, top: 48, bottom: 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () => Navigator.of(context).pop(),
                                  tooltip: 'Back',
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add New Course',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.school,
                                color: Colors.white, size: 32),
                          ],
                        ),
                      ),
                      // Form card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth > 700
                              ? horizontalPadding
                              : 16,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 28),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Course Title",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900]),
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _titleController,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          labelText: "Course Title",
                                          prefixIcon: const Icon(Icons.title,
                                              color: Colors.blue),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.blue, width: 2),
                                          ),
                                        ),
                                        validator: (value) => value!.isEmpty
                                            ? "Title cannot be empty"
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Course Description",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900]),
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _descriptionController,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          labelText: "Course Description",
                                          prefixIcon: const Icon(
                                              Icons.description,
                                              color: Colors.blue),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.blue, width: 2),
                                          ),
                                        ),
                                        validator: (value) => value!.isEmpty
                                            ? "Description cannot be empty"
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Select Course Type",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900]),
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        value: _selectedCourseType,
                                        items: _courseTypes
                                            .map((courseType) =>
                                                DropdownMenuItem<String>(
                                                  value: courseType,
                                                  child: Text(courseType),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedCourseType = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: "Course Type",
                                          prefixIcon: const Icon(Icons.category,
                                              color: Colors.blue),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.blue, width: 2),
                                          ),
                                        ),
                                        validator: (value) => value == null
                                            ? "Please select a course type"
                                            : null,
                                      ),
                                      const SizedBox(height: 24),
                                      Divider(color: Colors.blue[100]),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Course Poster",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.blue[200]!),
                                        ),
                                        child: InkWell(
                                          onTap: _isImageUploading
                                              ? null
                                              : _pickImage,
                                          child: _posterImage != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Image.file(
                                                        _posterImage!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                      if (_isImageUploading)
                                                        Container(
                                                          color: Colors.black54,
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      Positioned(
                                                        bottom: 8,
                                                        right: 8,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: const Icon(
                                                            Icons.edit,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .add_photo_alternate,
                                                        size: 48,
                                                        color: Colors.blue[300],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        "Add Course Poster",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.blue[300],
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isImageUploading
                                              ? null
                                              : _pickImage,
                                          icon: const Icon(Icons.upload,
                                              color: Colors.white),
                                          label: Text(
                                            _isImageUploading
                                                ? "Uploading..."
                                                : _posterImage == null
                                                    ? "Upload Poster"
                                                    : "Change Poster",
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Divider(color: Colors.blue[100]),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Course Benefits",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900]),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _benefitController,
                                              maxLines: null,
                                              decoration: InputDecoration(
                                                labelText: "Enter Benefit",
                                                prefixIcon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.blue),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: Colors.blue,
                                                      width: 2),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _addBenefit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Icon(Icons.add),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (_benefitsList.isNotEmpty)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                              _benefitsList.length, (index) {
                                            return Chip(
                                              label: Text(_benefitsList[index]),
                                              deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Colors.red),
                                              onDeleted: () =>
                                                  _removeBenefit(index),
                                              backgroundColor: Colors.blue[50],
                                              labelStyle: const TextStyle(
                                                  color: Colors.blue),
                                            );
                                          }),
                                        ),
                                      const SizedBox(height: 16),
                                      Divider(color: Colors.blue[100]),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Skills You Will Achieve",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900]),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _skillController,
                                              maxLines: null,
                                              decoration: InputDecoration(
                                                labelText: "Enter Skill",
                                                prefixIcon: const Icon(
                                                    Icons.star,
                                                    color: Colors.blue),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: Colors.blue,
                                                      width: 2),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _addSkill,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Icon(Icons.add),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (_skillsList.isNotEmpty)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                              _skillsList.length, (index) {
                                            return Chip(
                                              label: Text(_skillsList[index]),
                                              deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Colors.red),
                                              onDeleted: () =>
                                                  _removeSkill(index),
                                              backgroundColor: Colors.blue[50],
                                              labelStyle: const TextStyle(
                                                  color: Colors.blue),
                                            );
                                          }),
                                        ),
                                      const SizedBox(height: 16),
                                      Divider(color: Colors.blue[100]),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Course Price",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900]),
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _priceController,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          labelText: "Course Price (Rs)",
                                          prefixIcon: const Icon(
                                              Icons.currency_rupee,
                                              color: Colors.blue),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.blue, width: 2),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value!.isEmpty
                                            ? "Please enter the course price"
                                            : null,
                                      ),
                                      const SizedBox(height: 28),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isUploading
                                              ? null
                                              : _navigateToAddChapters,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 18),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            textStyle: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          child: _isUploading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2),
                                                )
                                              : const Text("Add Course"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
