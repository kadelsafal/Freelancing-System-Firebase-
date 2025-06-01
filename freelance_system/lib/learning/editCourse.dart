import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/editchapter.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Editcourse extends StatefulWidget {
  final String courseId;
  final String title;
  const Editcourse({super.key, required this.courseId, required this.title});

  @override
  State<Editcourse> createState() => _EditcourseState();
}

class _EditcourseState extends State<Editcourse> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _benefitController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  String? _selectedCourseType;
  List<String> _skillsList = [];
  List<String> _benefitsList = [];
  bool isLoading = false;
  String? _posterUrl;

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

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  Future<void> _fetchCourseData() async {
    setState(() {
      isLoading = true;
    });

    try {
      var doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _priceController.text = data['price']?.toString() ?? '';
        _selectedCourseType = data['courseType'] ?? _courseTypes[0];
        _posterUrl = data['posterUrl'];

        _skillsList = List<String>.from(data['skills'] ?? []);
        _benefitsList = List<String>.from(data['benefits'] ?? []);
      }
    } catch (e) {
      print("Error fetching course data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking image')),
      );
    }
  }

  // Upload File to Cloudinary (Image)
  Future<String?> uploadFileToCloudinary(File file) async {
    final String cloudName = "dnebaumu9";
    final String uploadPreset = "Post Images";
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
      print("File upload failed: \\${response.statusCode} - \\${responseData}");
      return null;
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _posterUrl;

    try {
      setState(() => _isUploading = true);

      String? imageUrl = await uploadFileToCloudinary(_imageFile!);

      setState(() => _isUploading = false);
      return imageUrl ?? _posterUrl;
    } catch (e) {
      print("Error uploading image: $e");
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
      return _posterUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Course',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title Section
                      _buildSectionTitle("Course Title"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Enter course title',
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 32),

                      // Course Description Section
                      _buildSectionTitle("Course Description"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Enter course description',
                        maxLines: 4,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a description' : null,
                      ),
                      const SizedBox(height: 32),

                      // Course Type Section
                      _buildSectionTitle("Course Type"),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCourseType,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            border: InputBorder.none,
                          ),
                          items: _courseTypes.map((courseType) {
                            return DropdownMenuItem<String>(
                              value: courseType,
                              child: Text(
                                courseType,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCourseType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Skills Section
                      _buildSectionTitle("Skills"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _skillsController,
                        label: 'Add skill',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF1976D2), size: 32),
                          onPressed: _addSkill,
                        ),
                        onFieldSubmitted: (_) => _addSkill(),
                      ),
                      const SizedBox(height: 16),
                      _buildChipList(_skillsList, _removeSkill),
                      const SizedBox(height: 32),

                      // Benefits Section
                      _buildSectionTitle("Benefits"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _benefitController,
                        label: 'Add benefit',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF1976D2), size: 32),
                          onPressed: _addBenefit,
                        ),
                        onFieldSubmitted: (_) => _addBenefit(),
                      ),
                      const SizedBox(height: 16),
                      _buildChipList(_benefitsList, _removeBenefit),
                      const SizedBox(height: 32),

                      // Price Section
                      _buildSectionTitle("Price"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _priceController,
                        label: 'Enter price',
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a price' : null,
                      ),
                      const SizedBox(height: 32),

                      // Course Poster Section
                      _buildSectionTitle("Course Poster"),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isUploading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _imageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _posterUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Image.network(
                                              _posterUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return _buildPosterPlaceholder();
                                              },
                                            ),
                                          )
                                        : _buildPosterPlaceholder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.add_photo_alternate,
                            size: 36,
                            color: Color(0xFF1976D2),
                          ),
                          label: const Text(
                            'Add/Change Poster',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Proceed Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _isUploading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // Upload image if selected
                                      String? updatedPosterUrl =
                                          await _uploadImage();

                                      var updatedData = {
                                        'title': _titleController.text,
                                        'description':
                                            _descriptionController.text,
                                        'price': double.tryParse(
                                            _priceController.text),
                                        'skills': _skillsList,
                                        'courseType': _selectedCourseType,
                                        'benefits': _benefitsList,
                                        'posterUrl': updatedPosterUrl,
                                      };

                                      await FirebaseFirestore.instance
                                          .collection('courses')
                                          .doc(widget.courseId)
                                          .update(updatedData);

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Course updated successfully!')),
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditChapter(
                                              courseId: widget.courseId,
                                              posterUrl: updatedPosterUrl,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print("Error updating course: $e");
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Error updating course')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isUploading || isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save & Proceed to Chapters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1976D2),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  Widget _buildChipList(List<String> items, Function(int) onRemove) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: items
          .map((item) => Chip(
                label: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                labelStyle: const TextStyle(color: Color(0xFF1976D2)),
                deleteIconColor: const Color(0xFF1976D2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onDeleted: () => onRemove(items.indexOf(item)),
              ))
          .toList(),
    );
  }

  Widget _buildPosterPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Add Course Poster',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _addSkill() {
    String newSkill = _skillsController.text.trim();
    if (newSkill.isNotEmpty && !_skillsList.contains(newSkill)) {
      setState(() {
        _skillsList.add(newSkill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skillsList.removeAt(index);
    });
  }

  void _addBenefit() {
    String newBenefit = _benefitController.text.trim();
    if (newBenefit.isNotEmpty && !_benefitsList.contains(newBenefit)) {
      setState(() {
        _benefitsList.add(newBenefit);
        _benefitController.clear();
      });
    }
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefitsList.removeAt(index);
    });
  }
}
