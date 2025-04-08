import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../screens/project.dart';

class AddProject extends StatefulWidget {
  const AddProject({super.key});

  @override
  State<AddProject> createState() => _AddProjectState();
}

class _AddProjectState extends State<AddProject> {
  final _formKey = GlobalKey<FormState>(); // Key to manage the form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  final List<TextEditingController> _preferencesControllers =
      []; // List of controllers for preferences
  List<String> preferences = []; // To hold the list of preferences/skills

  @override
  void dispose() {
    // Dispose all the controllers when the widget is disposed
    for (var controller in _preferencesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPreference() {
    setState(() {
      _preferencesControllers.add(
          TextEditingController()); // Add a new TextEditingController for a new preference
    });
  }

  void _removePreference(int index) {
    setState(() {
      _preferencesControllers
          .removeAt(index); // Remove the controller at the specified index
    });
  }

  Future<void> saveproject() async {
    try {
      //Collect data from the fields
      String title = _titleController.text.trim();
      String description = _descriptionController.text.trim();
      String budget = _budgetController.text.trim();
      String deadline = _deadlineController.text.trim();
      List<String> skills = _preferencesControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }
      String userId = user.uid;

      //Generate a project ID
      String projectId =
          FirebaseFirestore.instance.collection('projects').doc().id;

      //Set initial values
      String status = 'New'; // Initial Project Staus
      String? appointedFreelancerId;
      String? appointedFreelancer;

      List<String> appliedIndividuals = [];

      //Save data to Firebase
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .set({
        'projectId': projectId,
        'userId': userId,
        'title': title,
        'description': description,
        'budget':
            double.tryParse(budget) ?? 0.0, // Handle invalid number inputs
        'preferences': skills,
        'status': status,
        'appointedFreelancerId': appointedFreelancerId,
        'appointedFreelancer': appointedFreelancer,

        'appliedIndividuals': appliedIndividuals,
        'createdAt': FieldValue.serverTimestamp(),
        'deadline': deadline
      });
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project added successfully')),
        );
        // Optionally, clear the form fields after submission
        _titleController.clear();
        _descriptionController.clear();
        _budgetController.clear();
        _deadlineController.clear();
        setState(() {
          _preferencesControllers.clear(); // Clear preferences list
        });
      }
      // Show success message
    } catch (e) {
      // Show error message if saving failed
      if (mounted) {
        // Show error message if saving failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add project: $e')),
        );
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // If form is valid, process data

      if (mounted) {
        setState(() {
          preferences = _preferencesControllers
              .map((controller) => controller.text.trim())
              .where((text) =>
                  text.isNotEmpty) // Ensure no empty preferences are added
              .toList();
        });
      }
      saveproject();
      // You can process the form data here, like sending it to a server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project added successfully')),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ProjectScreen()));
    }
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        initialDate: DateTime.now());

    if (pickedDate != null) {
      setState(() {
        _deadlineController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Add Project"),
            IconButton(
                onPressed: _submitForm,
                icon: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.deepPurple,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 40,
                    )))
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Title",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Project Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Description",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Label for Preferences
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Preferences (Skills)",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Preferences (Skills) Fields
                ..._preferencesControllers.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: 'Enter Skill',
                                  hintText: 'Skill ${entry.key + 1}',
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
                              icon: Icon(Icons.delete),
                              onPressed: () => _removePreference(entry.key),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),

                // Add Preference Button (Plus Icon)
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addPreference,
                  color: Colors.purple,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Budget",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                // Allocated Budget Field
                TextFormField(
                  controller: _budgetController,
                  decoration: InputDecoration(
                    labelText: 'Allocated Budget',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the budget';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Deadline",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _deadlineController,
                  readOnly: true, // Prevent manual typing
                  decoration: InputDecoration(
                    labelText: 'Deadline',
                    hintText: 'Select a date',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the date';
                    }
                    // No need to check for double values, just ensure it's a valid date
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
