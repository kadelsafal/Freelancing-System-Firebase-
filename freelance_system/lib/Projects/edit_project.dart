import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/screens/project.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProject extends StatefulWidget {
  final String
      projectId; // Pass the projectId to identify the project to update

  const EditProject({super.key, required this.projectId});

  @override
  _EditProjectState createState() => _EditProjectState();
}

class _EditProjectState extends State<EditProject> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  String? _status = "New";
  List<TextEditingController> _preferencesControllers =
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
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  // Fetch project data from Firestore to display in TextFormField
  Future<void> _fetchProjectData() async {
    var projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (projectDoc.exists) {
      var project = projectDoc.data()!;
      _titleController.text = project['title'];
      _descriptionController.text = project['description'];
      _budgetController.text = project['budget'].toString();
      _deadlineController.text = project['deadline'];
      _status = project['status'];
      List<dynamic> preferences = project['preferences'] ?? [];

      setState(() {
        _preferencesControllers = preferences
            .map((preference) => TextEditingController(text: preference))
            .toList();
      });
    }
  }

  // Update the project in Firestore
  Future<void> _updateProject() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'budget': double.parse(_budgetController.text),
        'deadline': _deadlineController.text,
        'status': _status,
        'preferences': _preferencesControllers
            .map((controller) => controller.text)
            .toList() // Save the preferences as text
      });
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ProjectScreen()));
      // After updating, go back to the previous screen or show a success message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Project Updated')));
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // If form is valid, process data
      setState(() {
        preferences = _preferencesControllers
            .map((controller) => controller.text.trim())
            .where((text) =>
                text.isNotEmpty) // Ensure no empty preferences are added
            .toList();
      });
      _updateProject();
      // You can process the form data here, like sending it to a server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project Updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Edit Project"),
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
                      "Status : ",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 213, 192, 246)),
                      child: DropdownButton<String>(
                        value: _status,
                        hint: Text('Select Status'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _status = newValue; // Update the selected status
                          });
                        },
                        items: <String>['New', 'Pending', 'Completed']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
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
                Column(
                  children: [
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
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addPreference,
                      color: Colors.purple,
                    ),
                  ],
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
