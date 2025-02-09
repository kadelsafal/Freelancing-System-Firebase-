import 'package:flutter/material.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import 'package:freelance_system/resume/pdf_generator.dart';

// Dynamically load all available templates (assuming modern_template.dart, etc.)
import 'package:freelance_system/resume/templates/modern_template.dart';

class SelectTemplates extends StatefulWidget {
  final Resume resume;
  const SelectTemplates({super.key, required this.resume});

  @override
  State<SelectTemplates> createState() => _SelectTemplatesState();
}

class _SelectTemplatesState extends State<SelectTemplates> {
  List<String> templates = ["Modern Template", "Template 2", "Template 3"];
  String selectedTemplate = "Modern Template"; // Default selected template

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text("Select Templates"),
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(templates.length, (index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: ListTile(
                onTap: () {
                  setState(() {
                    selectedTemplate = templates[index];
                  });

                  // Navigate to preview screen and pass selected template
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfGenerator(
                        resume: widget.resume,
                        selectedTemplate: selectedTemplate,
                      ),
                    ),
                    (route) => false,
                  );
                },
                title: Text(templates[index]),
                subtitle: Text("Tap to preview"),
                leading: Icon(Icons.insert_drive_file),
              ),
            );
          }),
        ),
      ),
    );
  }
}
