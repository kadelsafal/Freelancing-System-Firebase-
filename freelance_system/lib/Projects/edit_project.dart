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
            .toList()
      });
      Navigator.pop(context);
      // After updating, show a success message
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Edit Project",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _submitForm,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.blue.shade700,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Status : ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: DropdownButton<String>(
                      value: _status,
                      hint: Text('Select Status'),
                      style: TextStyle(color: Colors.blue.shade700),
                      underline: SizedBox(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _status = newValue;
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
              const SizedBox(height: 20),
              Text(
                "Title",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Project Title',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  hintText: 'Enter your project title',
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
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Description",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  hintText: 'Enter project description',
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
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Preferences (Skills)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
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
                                    labelStyle:
                                        TextStyle(color: Colors.blue.shade700),
                                    hintText: 'Skill ${entry.key + 1}',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade700),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade200),
                                    ),
                                    filled: true,
                                    fillColor: Colors.blue.shade50,
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
                                icon: Icon(Icons.delete,
                                    color: Colors.red.shade400),
                                onPressed: () => _removePreference(entry.key),
                              ),
                            ],
                          ),
                        ),
                      ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.blue.shade700),
                    onPressed: _addPreference,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Budget",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Allocated Budget',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  hintText: 'Enter budget amount',
                  prefixIcon:
                      Icon(Icons.currency_rupee, color: Colors.blue.shade700),
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
                  fillColor: Colors.blue.shade50,
                ),
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
              const SizedBox(height: 20),
              Text(
                "Deadline",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Deadline',
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  hintText: 'Select a date',
                  suffixIcon:
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
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
                  fillColor: Colors.blue.shade50,
                ),
                onTap: () => selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Submit',
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
    );
  }
}
