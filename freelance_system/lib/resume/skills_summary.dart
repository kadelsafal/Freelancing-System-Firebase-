import 'package:flutter/material.dart';
import 'package:freelance_system/resume/pdf_page.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import 'package:freelance_system/resume/select_templates.dart';
import './resume_preview.dart';

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
  List<TextEditingController> _skillControllers = [];
  List<String> _skills = [];

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
      Navigator.push(
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
      appBar: AppBar(title: Text("Add Skills and Summary")),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Field
              _buildInputField(
                label: "Summary",
                controller: _summaryController,
                icon: Icons.description,
                maxLines: 3,
                validatorMessage: "Please enter a summary",
              ),
              SizedBox(height: 20),

              // Skills Fields
              Text(
                "Skills",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              ..._buildSkillFields(),
              SizedBox(height: 20),
              Center(
                child: IconButton(
                    onPressed: _addSkillField,
                    icon: Icon(
                      Icons.add,
                      size: 40,
                      color: Colors.deepPurple,
                    )),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitSkills,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 66, 1, 107),
                      foregroundColor:
                          Colors.white // Set the background color to purple
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "Save Resume",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
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

  // Generate Skill Fields dynamically
  List<Widget> _buildSkillFields() {
    List<Widget> fields = [];

    if (_skillControllers.isEmpty) {
      _addSkillField(); // Adding at least one skill field initially
    }

    for (int i = 0; i < _skillControllers.length; i++) {
      fields.add(
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skillControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Enter Skill',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a skill';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 30,
                  color: Colors.red,
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
