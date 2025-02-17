import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/editchapter.dart';
import 'package:freelance_system/navigation_bar.dart';

class Editcourse extends StatefulWidget {
  final String courseId;
  final String title;
  const Editcourse({super.key, required this.courseId, required this.title});

  @override
  State<Editcourse> createState() => _EditcourseState();
}

class _EditcourseState extends State<Editcourse> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _skillsController = TextEditingController();
  TextEditingController _benefitController = TextEditingController();

  String? _selectedCourseType;
  List<String> _skillsList = [];
  List<String> _benefitsList = [];
  bool isLoading = false;

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

  Future<void> _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        var updatedData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'price': double.tryParse(_priceController.text),
          'skills': _skillsList,
          'courseType': _selectedCourseType,
          'benefits': _benefitsList,
        };

        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationMenu()),
        );
      } catch (e) {
        print("Error updating course: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating course')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle,
                color: Colors.deepPurple, size: 38), // ✅ Checkmark icon
            onPressed: _updateCourse, // ✅ Calls update function
          ),
          const SizedBox(
              width: 16), // ✅ Adds spacing between icon and screen edge
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Course Title",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Course Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Course Description",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a description' : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Course Type",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCourseType,
                        decoration: const InputDecoration(
                          labelText: 'Course Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _courseTypes.map((courseType) {
                          return DropdownMenuItem<String>(
                            value: courseType,
                            child: Text(courseType),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Skills",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      // Skills Section
                      TextFormField(
                        controller: _skillsController,
                        decoration: InputDecoration(
                          labelText: 'Add Skill',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle,
                                size: 30, color: Colors.deepPurple),
                            onPressed: _addSkill,
                          ),
                        ),
                        maxLines: null,
                        onFieldSubmitted: (_) => _addSkill(),
                      ),

                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        children: _skillsList
                            .map((skill) => Chip(
                                  label: Text(skill),
                                  onDeleted: () =>
                                      _removeSkill(_skillsList.indexOf(skill)),
                                  deleteIconColor: Colors.red,
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 20),

// Benefits Section
                      Text(
                        "Benefits of the course",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _benefitController,
                        decoration: InputDecoration(
                          labelText: 'Add Benefit',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              size: 30,
                              color: Colors.deepPurple,
                            ),
                            onPressed: _addBenefit,
                          ),
                        ),
                        maxLines: null,
                        onFieldSubmitted: (_) => _addBenefit(),
                      ),

                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        children: _benefitsList
                            .map((benefit) => Chip(
                                  label: Text(benefit),
                                  onDeleted: () => _removeBenefit(
                                      _benefitsList.indexOf(benefit)),
                                  deleteIconColor: Colors.red,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Price",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter a price' : null,
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditChapter(courseId: widget.courseId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple, // ✅ Fixed
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Proceed to Chapters',
                            style: TextStyle(
                                color: Colors.white), // Ensures text is visible
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
