import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freelance_system/resume/education.dart';
import 'package:freelance_system/resume/resume_modal.dart';

class BuildResume extends StatefulWidget {
  const BuildResume({super.key});

  @override
  State<BuildResume> createState() => _BuildResumeState();
}

class _BuildResumeState extends State<BuildResume> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _addressControllers = [
    TextEditingController()
  ];
  String? _imagePath; // To store the path of the selected image

  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker
  bool isLoading = false;
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addAddressField() {
    setState(() {
      _addressControllers.add(TextEditingController());
    });
  }

  void _removeAddressField(int index) {
    if (_addressControllers.length > 1) {
      setState(() {
        _addressControllers[index].dispose();
        _addressControllers.removeAt(index);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      List<String> addresses =
          _addressControllers.map((controller) => controller.text).toList();

      Resume resume = Resume(
        imageUrl: _imagePath ?? '', // Use the selected image path
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: addresses,
        summary: '',
        skills: [],
        experiences: [],
        educations: [],
      );

      print("Full Name: ${resume.fullName}");
      print("Email: ${resume.email}");
      print("Phone: ${resume.phone}");
      print("Addresses: ${resume.address}");
      print("IMage: ${resume.imageUrl}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Personal details saved!")),
      );

      // Navigate to Education Details and pass Resume object
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EducationDetails(resume: resume),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      isLoading = true; // Set loading to true when starting image picking
    });

    // Pick an image from the gallery
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imagePath = pickedFile.path; // Store the path of the selected image
      }
      isLoading = false; // Set loading to false after the image is picked
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Add Personal Details",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade700),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image upload and preview
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
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
                        backgroundImage: _imagePath != null && !isLoading
                            ? FileImage(File(_imagePath!))
                            : null,
                        child: isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade700),
                              )
                            : _imagePath == null
                                ? Icon(
                                    Icons.add_a_photo,
                                    color: Colors.blue.shade700,
                                    size: 30,
                                  )
                                : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                _buildInputField(
                  label: "Full Name",
                  controller: _fullNameController,
                  icon: Icons.person,
                  validatorMessage: "Please enter a Full Name",
                ),
                _buildInputField(
                  label: "Email",
                  controller: _emailController,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validatorMessage: "Please enter a valid email address",
                  validator: (value) {
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!emailRegex.hasMatch(value)) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
                _buildInputField(
                  label: "Phone Number",
                  controller: _phoneController,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validatorMessage: "Enter a valid phone number",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Phone Number is required";
                    }
                    if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                ),
                Text(
                  "Address",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 10),

                // Address Fields
                ..._addressControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              labelText: 'Enter Address',
                              hintText: 'Address ${index + 1}',
                              labelStyle:
                                  TextStyle(color: Colors.blue.shade700),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              prefixIcon: Icon(Icons.location_on,
                                  color: Colors.blue.shade700),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            validator: (value) {
                              if (index == 0 &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter at least one address';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_addressControllers.length > 1)
                          IconButton(
                            icon:
                                Icon(Icons.delete, color: Colors.red.shade400),
                            onPressed: () => _removeAddressField(index),
                          ),
                      ],
                    ),
                  );
                }),

                // Add Address Button
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: _addAddressField,
                    color: Colors.blue.shade700,
                    iconSize: 32,
                  ),
                ),

                SizedBox(height: 30),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Next",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String validatorMessage,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: 'Enter $label',
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
              prefixIcon: Icon(icon, color: Colors.blue.shade700),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return validatorMessage;
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }
}
