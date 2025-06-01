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
  final List<Map<String, TextEditingController>> _experienceFields = [];

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Add Experience Details",
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
                Text(
                  "Work Experience",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 20),

                // Dynamically display experience fields
                ..._experienceFields.map((experienceField) {
                  int index = _experienceFields.indexOf(experienceField);
                  return Container(
                    margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red.shade400),
                              onPressed: () => _removeExperienceField(index),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                // Add Experience Button
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: _addExperienceField,
                    color: Colors.blue.shade700,
                    iconSize: 32,
                  ),
                ),

                SizedBox(height: 30),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitExperienceDetails,
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
    int? maxLines = 1,
    required String validatorMessage,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
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
              fillColor: Colors.white,
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
      padding: EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () => _selectDate(context, controller),
        child: AbsorbPointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Select $label',
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
                  fillColor: Colors.white,
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
        ),
      ),
    );
  }
}
