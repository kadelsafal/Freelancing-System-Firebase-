import 'package:flutter/material.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import './experiences.dart';

class EducationDetails extends StatefulWidget {
  final Resume resume; // Accept Resume object in the constructor

  const EducationDetails({super.key, required this.resume});

  @override
  State<EducationDetails> createState() => _EducationDetailsState();
}

class _EducationDetailsState extends State<EducationDetails> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _institutionControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _descriptionControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _degreeControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _startDateControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _endDateControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    for (var controller in [
      ..._institutionControllers,
      ..._degreeControllers,
      ..._startDateControllers,
      ..._endDateControllers,
      ..._descriptionControllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEducationField() {
    setState(() {
      _institutionControllers.add(TextEditingController());
      _degreeControllers.add(TextEditingController());
      _startDateControllers.add(TextEditingController());
      _endDateControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
    });
  }

  void _removeEducationField(int index) {
    if (_institutionControllers.length > 1) {
      setState(() {
        _institutionControllers[index].dispose();
        _degreeControllers[index].dispose();
        _startDateControllers[index].dispose();
        _endDateControllers[index].dispose();
        _institutionControllers.removeAt(index);
        _degreeControllers.removeAt(index);
        _startDateControllers.removeAt(index);
        _endDateControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a list of Education objects
      List<Education> educations = List.generate(
        _institutionControllers.length,
        (index) => Education(
          institution: _institutionControllers[index].text,
          degree: _degreeControllers[index].text,
          start_date: _startDateControllers[index].text,
          end_date: _endDateControllers[index].text,
          course: _descriptionControllers[index].text,
        ),
      );

      // Update the Resume object with the education details
      widget.resume.educations.addAll(educations);

      print("Education Details:");
      for (var edu in educations) {
        print("Institution: ${edu.institution}");
        print("Degree: ${edu.degree}");
        print("Start Date: ${edu.start_date}");
        print("End Date: ${edu.end_date}");
        print("Description: ${edu.course}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Education details submitted successfully!")),
      );

      // Navigate to the next screen (ExperiencesDetails) and pass the updated Resume object
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExperiencesDetails(resume: widget.resume),
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
          "Education Details",
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
                  "Education",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 20),

                // Dynamic Education Fields
                ..._institutionControllers.asMap().entries.map((entry) {
                  int index = entry.key;
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
                          label: "Institution Name",
                          controller: _institutionControllers[index],
                          icon: Icons.school,
                          validatorMessage: "Please enter an institution name",
                        ),
                        _buildInputField(
                          label: "Degree",
                          controller: _degreeControllers[index],
                          icon: Icons.book,
                          validatorMessage: "Please enter a degree",
                        ),
                        _buildDateField(
                          label: "Start Date",
                          controller: _startDateControllers[index],
                          icon: Icons.date_range,
                          validatorMessage: "Please select a start date",
                        ),
                        _buildDateField(
                          label: "End Date",
                          controller: _endDateControllers[index],
                          icon: Icons.date_range,
                          validatorMessage: "Please select an end date",
                        ),
                        _buildInputField(
                          label: "Course",
                          controller: _descriptionControllers[index],
                          icon: Icons.description,
                          maxLines: 2,
                          validatorMessage: "enter a course",
                        ),
                        if (_institutionControllers.length > 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red.shade400),
                              onPressed: () => _removeEducationField(index),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                // Add Education Button
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: _addEducationField,
                    color: Colors.blue.shade700,
                    iconSize: 32,
                  ),
                ),

                SizedBox(height: 30),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
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
