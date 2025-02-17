import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:provider/provider.dart';
import 'addchapter.dart';

class Addcourse extends StatefulWidget {
  const Addcourse({super.key});

  @override
  State<Addcourse> createState() => _AddcourseState();
}

class _AddcourseState extends State<Addcourse> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isUploading = false;

  final List<TextEditingController> _benefits = [TextEditingController()];
  final List<TextEditingController> _skills = [TextEditingController()];

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

  void _addField(List<TextEditingController> list) {
    setState(() {
      list.add(TextEditingController());
    });
  }

  void _removeField(List<TextEditingController> list, int index) {
    if (list.length > 1) {
      setState(() {
        list.removeAt(index);
      });
    }
  }

  Future<void> _navigateToAddChapters() async {
    if (!_formKey.currentState!.validate() || _selectedCourseType == null)
      return;

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
      "benefits": _benefits.map((e) => e.text.trim()).toList(),
      "skills": _skills.map((e) => e.text.trim()).toList(),
      "appliedUsers": 0,
      "courseType": _selectedCourseType, // Add the courseType here
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
        appBar: AppBar(title: const Text("Add Course")),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Course Title",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Course Title",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Title cannot be empty" : null,
                      maxLines: null, // This will allow unlimited lines
                      keyboardType:
                          TextInputType.multiline, // Allows multiline input
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Course Description",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Course Description",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),

                      validator: (value) =>
                          value!.isEmpty ? "Description cannot be empty" : null,
                      maxLines: null, // This will allow unlimited lines
                      keyboardType:
                          TextInputType.multiline, // Allows multiline input
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Select Course Type",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCourseType,
                      items: _courseTypes
                          .map((courseType) => DropdownMenuItem<String>(
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) =>
                          value == null ? "Please select a course type" : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Course Benefits",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: List.generate(_benefits.length, (index) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _benefits[index],
                                      decoration: InputDecoration(
                                        labelText: "Enter Benefit",
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0)),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? "Benefit cannot be empty"
                                          : null,
                                      maxLines:
                                          null, // This will allow unlimited lines
                                      keyboardType: TextInputType
                                          .multiline, // Allows multiline input
                                      textInputAction: TextInputAction.newline,
                                    ),
                                  ),
                                  if (index > 0)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeField(_benefits, index),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _addField(_benefits),
                        child: const Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Skills You will achieve through this Course",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: List.generate(_skills.length, (index) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _skills[index],
                                      decoration: InputDecoration(
                                        labelText: "Enter Skill",
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0)),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? "Skill cannot be empty"
                                          : null,
                                      maxLines:
                                          null, // This will allow unlimited lines
                                      keyboardType: TextInputType
                                          .multiline, // Allows multiline input
                                      textInputAction: TextInputAction.newline,
                                    ),
                                  ),
                                  if (index > 0)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeField(_skills, index),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _addField(_skills),
                        child: const Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Course Price",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: "Course Price",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty
                          ? "Please enter the course price"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              _isUploading ? null : _navigateToAddChapters,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.deepPurple),
                            foregroundColor: MaterialStateProperty.all(
                                const Color.fromARGB(255, 255, 255, 255)),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 30)), // Increased padding
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors
                                      .white, // Adjust color for better visibility on dark background
                                )
                              : const Text(
                                  "Add Course",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight
                                          .bold), // Adjust text style for better clarity
                                ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
