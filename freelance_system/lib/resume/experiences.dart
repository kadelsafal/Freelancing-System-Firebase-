import 'package:flutter/material.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import 'package:freelance_system/resume/skills_summary.dart'; // Import SkillsSummaryScreen

class ExperiencesDetails extends StatefulWidget {
  final Resume resume; // Accept Resume object in the constructor

  const ExperiencesDetails({super.key, required this.resume});

  @override
  State<ExperiencesDetails> createState() => _ExperiencesDetailsState();
}

class _ExperiencesDetailsState extends State<ExperiencesDetails> {
  final _formKey = GlobalKey<FormState>();

  // List to manage multiple experience inputs
  List<Map<String, TextEditingController>> _experienceFields = [];

  @override
  void initState() {
    super.initState();
    // Initialize with one empty set of experience fields
    _addExperienceField();
  }

  void _addExperienceField() {
    setState(() {
      // Add a new experience field group
      _experienceFields.add({
        'company': TextEditingController(),
        'position': TextEditingController(),
        'startDate': TextEditingController(),
        'endDate': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  void _removeExperienceField(int index) {
    setState(() {
      if (_experienceFields.length > 1) {
        _experienceFields
            .removeAt(index); // Remove the field set at the given index
      }
    });
  }

  @override
  void dispose() {
    // Dispose all controllers for each experience field
    for (var experienceField in _experienceFields) {
      experienceField['company']?.dispose();
      experienceField['position']?.dispose();
      experienceField['startDate']?.dispose();
      experienceField['endDate']?.dispose();
      experienceField['description']?.dispose();
    }
    super.dispose();
  }

  void _submitExperienceDetails() {
    if (_formKey.currentState!.validate()) {
      // Loop through all experience fields and add them to the resume
      for (var experienceField in _experienceFields) {
        Experience newExperience = Experience(
          company: experienceField['company']!.text,
          position: experienceField['position']!.text,
          start_date: experienceField['startDate']!.text,
          end_date: experienceField['endDate']!.text,
          description: experienceField['description']!.text,
        );

        widget.resume.experiences.add(newExperience);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Experience details saved!")),
      );

      // Navigate to Skills Summary and pass the updated Resume
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SkillsSummaryScreen(resume: widget.resume),
        ),
      );
    }
  }

  // Date Picker function
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text =
          '${picked.toLocal()}'.split(' ')[0]; // Format as yyyy-MM-dd
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Experience Details")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamically display experience fields
                ..._experienceFields.map((experienceField) {
                  int index = _experienceFields.indexOf(experienceField);
                  return Column(
                    children: [
                      _buildInputField(
                        label: "Company",
                        controller: experienceField['company']!,
                        icon: Icons.business,
                        validatorMessage: "Please enter the company name",
                      ),
                      _buildInputField(
                        label: "Position",
                        controller: experienceField['position']!,
                        icon: Icons.work,
                        validatorMessage: "Please enter the position",
                      ),
                      _buildDateField(
                        label: "Start Date",
                        controller: experienceField['startDate']!,
                        icon: Icons.calendar_today,
                        validatorMessage: "Please enter the start date",
                      ),
                      _buildDateField(
                        label: "End Date",
                        controller: experienceField['endDate']!,
                        icon: Icons.calendar_today,
                        validatorMessage: "Please enter the end date",
                      ),
                      _buildInputField(
                        label: "Description",
                        controller: experienceField['description']!,
                        maxLines: 3,
                        icon: Icons.description,
                        validatorMessage: "Please enter a description",
                      ),
                      if (_experienceFields.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeExperienceField(index),
                        ),
                      SizedBox(height: 15),
                    ],
                  );
                }).toList(),
                // Plus Icon to add new experience fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addExperienceField,
                      color: Colors.deepPurple,
                      iconSize: 40,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitExperienceDetails,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 66, 1, 107),
                        foregroundColor:
                            Colors.white // Set the background color to purple
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "Next",
                        style: TextStyle(fontSize: 20),
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
    int? maxLines = 1,
    required String validatorMessage,
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
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: 'Enter $label',
              border: OutlineInputBorder(),
              prefixIcon: Icon(icon),
            ),
            validator: (value) {
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

  // Date Field Widget for selecting dates
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String validatorMessage,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectDate(context, controller),
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              prefixIcon: Icon(icon),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return validatorMessage;
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
