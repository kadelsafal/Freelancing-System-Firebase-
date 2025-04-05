// edit_resume_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditResumeDialog extends StatefulWidget {
  final Map<String, List<String>> entities;
  final String currentUserId;

  EditResumeDialog({required this.entities, required this.currentUserId});

  @override
  _EditResumeDialogState createState() => _EditResumeDialogState();
}

class _EditResumeDialogState extends State<EditResumeDialog> {
  late Map<String, TextEditingController> controllers;
  late List<Map<String, TextEditingController>> workExperienceControllers;
  late TextEditingController yearsOfExperienceController;
  late TextEditingController skillController;
  late List<String> skillsList;

  @override
  void initState() {
    super.initState();
    controllers = {};
    workExperienceControllers = [];
    skillsList = widget.entities["SKILLS"] ?? [];

    widget.entities.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.join(", "));
    });

    // Prepare work experience controllers
    _prepareWorkExperienceControllers();

    // Initialize years of experience controller
    yearsOfExperienceController = TextEditingController(
      text: widget.entities["YEARS OF EXPERIENCE"]?.first ?? "",
    );

    // Initialize skill controller
    skillController = TextEditingController();
  }

  void _prepareWorkExperienceControllers() {
    final workedAsList = widget.entities["WORKED AS"] ?? [];
    final companiesList = widget.entities["COMPANIES WORKED AT"] ?? [];
    final durationList = widget.entities["DURATION"] ?? [];

    final maxLength = [
      workedAsList.length,
      companiesList.length,
      durationList.length
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      workExperienceControllers.add({
        "workedAs": TextEditingController(
            text: i < workedAsList.length ? workedAsList[i] : ""),
        "company": TextEditingController(
            text: i < companiesList.length ? companiesList[i] : ""),
        "duration": TextEditingController(
            text: i < durationList.length ? durationList[i] : ""),
      });
    }

    // Add one empty entry if there are no work experience records
    if (workExperienceControllers.isEmpty) {
      workExperienceControllers.add({
        "workedAs": TextEditingController(),
        "company": TextEditingController(),
        "duration": TextEditingController(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Resume Info"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: yearsOfExperienceController,
              decoration: InputDecoration(labelText: "Years of Experience"),
              onChanged: (value) {
                widget.entities["YEARS OF EXPERIENCE"] = [value];
              },
            ),
            SizedBox(height: 20),
            Text("Work Experience:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...workExperienceControllers.asMap().entries.map((entry) {
              int i = entry.key;
              var map = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Work Experience ${i + 1}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  TextField(
                      controller: map["workedAs"],
                      decoration: InputDecoration(labelText: "Worked As")),
                  TextField(
                      controller: map["company"],
                      decoration: InputDecoration(labelText: "Company")),
                  TextField(
                      controller: map["duration"],
                      decoration: InputDecoration(labelText: "Duration")),
                  SizedBox(height: 15),
                ],
              );
            }).toList(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  workExperienceControllers.add({
                    "workedAs": TextEditingController(),
                    "company": TextEditingController(),
                    "duration": TextEditingController(),
                  });
                });
              },
              icon: Icon(Icons.add),
              label: Text("Add Work Experience"),
            ),
            SizedBox(height: 20),
            Text("Skills:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: skillsList
                  .map<Widget>((skill) => Chip(
                        label: Text(skill),
                        onDeleted: () {
                          setState(() {
                            skillsList.remove(skill);
                          });
                        },
                        deleteIconColor: Colors.red,
                      ))
                  .toList(),
            ),
            SizedBox(height: 10),
            TextField(
              controller: skillController,
              decoration: InputDecoration(labelText: "Add Skill"),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    skillsList.add(value);
                    skillController.clear();
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ...widget.entities.keys.where((key) {
              final lowerKey = key.toLowerCase();
              return lowerKey != "worked as" &&
                  lowerKey != "duration" &&
                  lowerKey != "companies worked at" &&
                  lowerKey != "skills" &&
                  lowerKey != "years of experience";
            }).map((key) {
              controllers.putIfAbsent(
                key,
                () => TextEditingController(
                    text: widget.entities[key]?.join(", ") ?? ""),
              );
              return TextField(
                controller: controllers[key],
                decoration: InputDecoration(labelText: key),
                maxLines: 2,
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Map<String, List<String>> updatedEntities = {};

            controllers.forEach((key, controller) {
              updatedEntities[key] = controller.text
                  .split(",")
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            });

            updatedEntities["WORKED AS"] = workExperienceControllers
                .map((e) => e["workedAs"]!.text)
                .where((text) => text.isNotEmpty)
                .toList();
            updatedEntities["COMPANIES WORKED AT"] = workExperienceControllers
                .map((e) => e["company"]!.text)
                .where((text) => text.isNotEmpty)
                .toList();
            updatedEntities["DURATION"] = workExperienceControllers
                .map((e) => e["duration"]!.text)
                .where((text) => text.isNotEmpty)
                .toList();
            updatedEntities["SKILLS"] = List<String>.from(skillsList);

            // Ensure that the 'YEARS OF EXPERIENCE' field is updated
            updatedEntities["YEARS OF EXPERIENCE"] = [
              yearsOfExperienceController.text.trim()
            ];
            updatedEntities.removeWhere((key, value) =>
                key.toLowerCase() == 'name' ||
                key.toLowerCase() == 'email address' ||
                key.toLowerCase() == 'email');

            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentUserId)
                .set(
              {'resume_entities': updatedEntities},
              SetOptions(merge: true),
            );

            Navigator.pop(context);
          },
          child: Text("Submit"),
        ),
      ],
    );
  }
}
