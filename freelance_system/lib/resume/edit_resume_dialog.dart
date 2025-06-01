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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    controllers = {};
    workExperienceControllers = [];
    skillsList = widget.entities["SKILLS"] ?? [];

    widget.entities.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.join(", "));
    });

    _prepareWorkExperienceControllers();
    yearsOfExperienceController = TextEditingController(
      text: widget.entities["YEARS OF EXPERIENCE"]?.first ?? "",
    );
    skillController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose all controllers
    controllers.values.forEach((controller) => controller.dispose());
    workExperienceControllers.forEach((map) {
      map.values.forEach((controller) => controller.dispose());
    });
    yearsOfExperienceController.dispose();
    skillController.dispose();
    super.dispose();
  }

  void _prepareWorkExperienceControllers() {
    final workedAsList = widget.entities["WORKED AS"] ?? [];
    final companiesList = widget.entities["COMPANIES WORKED AT"] ?? [];
    final durationList = widget.entities["DURATION"] ?? [];

    // Limit to maximum 2 experiences
    final maxLength = [
      workedAsList.length,
      companiesList.length,
      durationList.length
    ].reduce((a, b) => a > b ? a : b).clamp(0, 2);

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

    // Add empty experience if none exists
    if (workExperienceControllers.isEmpty) {
      workExperienceControllers.add({
        "workedAs": TextEditingController(),
        "company": TextEditingController(),
        "duration": TextEditingController(),
      });
    }
  }

  void _addWorkExperience() {
    if (!mounted) return;

    if (workExperienceControllers.length < 2) {
      setState(() {
        workExperienceControllers.add({
          "workedAs": TextEditingController(),
          "company": TextEditingController(),
          "duration": TextEditingController(),
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Maximum 2 work experiences allowed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeWorkExperience(int index) {
    if (!mounted) return;

    setState(() {
      workExperienceControllers.removeAt(index);
    });
  }

  void _addSkill() {
    if (!mounted) return;

    if (skillController.text.isNotEmpty) {
      setState(() {
        skillsList.add(skillController.text);
        skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    if (!mounted) return;

    setState(() {
      skillsList.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
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

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving changes: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSaving) return false;
        return true;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Resume Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _isSaving,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Skills Section (Moved to top)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Skills",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Add your key skills and expertise",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    skillsList.asMap().entries.map((entry) {
                                  return Chip(
                                    label: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    deleteIcon: Icon(Icons.close, size: 18),
                                    onDeleted: () => _removeSkill(entry.key),
                                    backgroundColor: Colors.white,
                                    side:
                                        BorderSide(color: Colors.blue.shade200),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: skillController,
                                      decoration: InputDecoration(
                                        hintText: "Add a skill",
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      onSubmitted: (_) => _addSkill(),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _addSkill,
                                    icon: Icon(Icons.add),
                                    label: Text("Add"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Years of Experience
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Years of Experience",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              TextField(
                                controller: yearsOfExperienceController,
                                decoration: InputDecoration(
                                  hintText: "Enter years of experience",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Work Experience Section
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Work Experience",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              if (workExperienceControllers.length < 2)
                                TextButton.icon(
                                  onPressed: _addWorkExperience,
                                  icon: Icon(Icons.add,
                                      color: Colors.blue.shade700),
                                  label: Text(
                                    "Add Experience",
                                    style:
                                        TextStyle(color: Colors.blue.shade700),
                                  ),
                                ),
                              SizedBox(height: 12),
                              Text(
                                "Add up to 2 most recent work experiences",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 16),
                              ...workExperienceControllers
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                int i = entry.key;
                                var map = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Experience ${i + 1}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _removeWorkExperience(i),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      TextField(
                                        controller: map["workedAs"],
                                        decoration: InputDecoration(
                                          labelText: "Position",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TextField(
                                        controller: map["company"],
                                        decoration: InputDecoration(
                                          labelText: "Company",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TextField(
                                        controller: map["duration"],
                                        decoration: InputDecoration(
                                          labelText: "Duration",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
