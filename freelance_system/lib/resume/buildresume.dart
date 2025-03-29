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
      appBar: AppBar(title: Text("Add Personal Details")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image upload and preview
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imagePath != null && !isLoading
                          ? FileImage(File(_imagePath!))
                          : null,
                      child: isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            )
                          : _imagePath == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey[700],
                                  size: 30,
                                )
                              : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),

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
                Text("Address",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
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
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeAddressField(index),
                            color: Colors.red,
                          ),
                      ],
                    ),
                  );
                }),

                // Add Address Button
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addAddressField,
                    color: Colors.purple,
                  ),
                ),

                SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text("Next"),
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
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: 'Enter $label',
              border: OutlineInputBorder(),
              prefixIcon: Icon(icon),
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
