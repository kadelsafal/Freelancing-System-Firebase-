import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyModalSheet extends StatefulWidget {
  final String projectId;
  const ApplyModalSheet({super.key, required this.projectId});

  @override
  _ApplyModalSheetState createState() => _ApplyModalSheetState();
}

class _ApplyModalSheetState extends State<ApplyModalSheet> {
  late TextEditingController _idController;
  late TextEditingController _nameController;
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _skillsList = [];
  final _form = GlobalKey<FormState>();

  bool _isUploadingFiles = false;
  bool _isFileUploaded = false;
  String? _uploadedFileName;
  String? _uploadedFileUrl;

  // Cloudinary Credentials
  final String cloudName = "dnebaumu9";
  final String uploadPreset = "Post Images";

  Future<String?> uploadFileToCloudinary(File file) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/upload");
    var request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(responseData);
      return jsonResponse["secure_url"];
    } else {
      print("File upload failed: ${response.statusCode} - $responseData");
      return null;
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Allow only one file
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isUploadingFiles = true;
      });

      File selectedFile = File(result.files.single.path!);

      String? fileUrl = await uploadFileToCloudinary(selectedFile);

      setState(() {
        if (fileUrl != null) {
          _uploadedFileName = result.files.single.name;
          _uploadedFileUrl = fileUrl;
          _isFileUploaded = true;
        }
        _isUploadingFiles = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_form.currentState!.validate()) {
      var userProvider = Provider.of<Userprovider>(context, listen: false);

      // Prepare data for submission
      final applicationData = {
        "userId": userProvider.userId,
        "name": userProvider.userName,
        "skills": _skillsList,
        "description": _descriptionController.text,
        "uploadedFile": _uploadedFileUrl, // Storing the file URL
      };

      try {
        // Submit to Firestore "appliedIndividuals" collection
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId) // Specify the project ID
            .update({
          'appliedIndividuals': FieldValue.arrayUnion([applicationData]),
        });
        // Show confirmation and close the modal
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Application submitted successfully')));
        Navigator.of(context).pop();
      } catch (e) {
        print("Error submitting application: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting application')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    _idController = TextEditingController(text: userProvider.userId);
    _nameController = TextEditingController(text: userProvider.userName);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _addSkill() {
    String newSkill = _skillsController.text.trim();
    if (newSkill.isNotEmpty && !_skillsList.contains(newSkill)) {
      setState(() {
        _skillsList.add(newSkill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skillsList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Container(
                constraints:
                    BoxConstraints(maxHeight: constraints.maxHeight * 0.8),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40)),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Apply for Project',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                          IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                              color: Colors.blue),
                        ],
                      ),
                    ),
                    Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("User ID:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                TextFormField(
                                    controller: _idController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder())),
                                SizedBox(height: 15),
                                Text("Name:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                TextFormField(
                                    controller: _nameController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder())),
                                SizedBox(height: 15),
                                Text("Skills",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue)),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: _skillsController,
                                  decoration: InputDecoration(
                                      labelText: 'Add Skill',
                                      suffixIcon: IconButton(
                                          icon: Icon(Icons.add_circle,
                                              size: 30, color: Colors.blue),
                                          onPressed: _addSkill)),
                                ),
                                SizedBox(height: 10),
                                Wrap(
                                  spacing: 8.0,
                                  children: _skillsList
                                      .asMap()
                                      .entries
                                      .map((entry) => Chip(
                                          label: Text(entry.value),
                                          onDeleted: () =>
                                              _removeSkill(entry.key),
                                          deleteIconColor: Colors.red))
                                      .toList(),
                                ),
                                SizedBox(height: 20),
                                Text("Description:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 10),
                                TextFormField(
                                    controller: _descriptionController,
                                    maxLines: null,
                                    minLines: 4,
                                    decoration: InputDecoration(
                                        labelText: "Description",
                                        border: OutlineInputBorder())),
                                SizedBox(height: 25),
                                Text("Upload File:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 10),
                                _isUploadingFiles
                                    ? Center(child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: _isFileUploaded
                                            ? null // Disable button after upload
                                            : _pickFile,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white),
                                        child: Text('Choose File'),
                                      ),
                                SizedBox(height: 10),
                                if (_isFileUploaded) ...[
                                  Text(
                                      "Uploaded File: ${_uploadedFileName!.split('/').last}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                                SizedBox(height: 25),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _submitApplication,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white),
                                    child: Text('Submit'),
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
