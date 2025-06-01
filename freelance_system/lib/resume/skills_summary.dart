import 'package:flutter/material.dart';
import 'package:freelance_system/resume/pdf_page.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import 'package:freelance_system/resume/select_templates.dart';

class SkillsSummaryScreen extends StatefulWidget {
  final Resume resume; // Accept Resume object in the constructor

  const SkillsSummaryScreen({super.key, required this.resume});

  @override
  State<SkillsSummaryScreen> createState() => _SkillsSummaryScreenState();
}

class _SkillsSummaryScreenState extends State<SkillsSummaryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _skillsController = TextEditingController();
  final _summaryController = TextEditingController();
  final List<TextEditingController> _skillControllers = [];
  final List<String> _skills = [];

  @override
  void dispose() {
    _skillsController.dispose();
    _summaryController.dispose();
    for (var controller in _skillControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSkillField() {
    setState(() {
      _skillControllers.add(TextEditingController());
    });
  }

  void _removeSkillField(int index) {
    setState(() {
      _skillControllers.removeAt(index);
    });
  }

  void _submitSkills() {
    if (_formKey.currentState!.validate()) {
      // Collect all skills from controllers
      for (var controller in _skillControllers) {
        _skills.add(controller.text);
      }
      // Add the summary text
      widget.resume.summary = _summaryController.text;

      // Add skills to the Resume object
      widget.resume.skills = _skills;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Resume saved successfully!")),
      );

      // Navigate to Preview screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => SelectTemplates(resume: widget.resume)
            // PdfPage(resume: widget.resume),
            ),
      );
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
          "Add Skills and Summary",
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
                  "Professional Summary",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 20),

                // Summary Field
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: _buildInputField(
                    label: "Summary",
                    controller: _summaryController,
                    icon: Icons.description,
                    maxLines: 3,
                    validatorMessage: "Please enter a summary",
                  ),
                ),
                SizedBox(height: 30),

                // Skills Section
                Text(
                  "Skills",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 20),

                // Skills Fields
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      ..._buildSkillFields(),
                      SizedBox(height: 15),
                      Align(
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          onPressed: _addSkillField,
                          color: Colors.blue.shade700,
                          iconSize: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitSkills,
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
                      "Save Resume",
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
    return Column(
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
    );
  }

  // Generate Skill Fields dynamically
  List<Widget> _buildSkillFields() {
    List<Widget> fields = [];

    if (_skillControllers.isEmpty) {
      _addSkillField(); // Adding at least one skill field initially
    }

    for (int i = 0; i < _skillControllers.length; i++) {
      fields.add(
        Padding(
          padding: EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skillControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Enter Skill',
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
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a skill';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red.shade400,
                ),
                onPressed: () => _removeSkillField(i),
              ),
            ],
          ),
        ),
      );
    }

    return fields;
  }
}
