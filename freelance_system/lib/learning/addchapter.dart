import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:freelance_system/screens/elearning.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class AddChapter extends StatefulWidget {
  final String courseId;
  const AddChapter({super.key, required this.courseId});

  @override
  State<AddChapter> createState() => _AddChapterState();
}

class _AddChapterState extends State<AddChapter> {
  // Add flags for video and file uploads
  bool _isUploadingVideo = false;
  bool _isUploadingFiles = false;
  // Cloudinary Credentials
  final String cloudName = "dnebaumu9";
  final String uploadPreset = "Post Images";
  final List<Map<String, dynamic>> _chapters = [
    {
      'titleController': TextEditingController(),
      'descriptionController': TextEditingController(),
      'learningPoints': [TextEditingController()],
      'uploadedFiles': <String>[],
      'uploadedVideo': null,
      'videoDuration': null,
      'isUploading': false,
    }
  ];

  bool _isLoading = false;
  double _uploadProgress = 0.0;

  void _addChapter() {
    setState(() {
      _chapters.add({
        'titleController': TextEditingController(),
        'descriptionController': TextEditingController(),
        'learningPoints': [TextEditingController()],
        'uploadedFiles': <String>[],
        'uploadedVideo': null,
        'videoDuration': null,
        'isUploading': false,
      });
    });
  }

  void _addLearningPoint(int chapterIndex) {
    setState(() {
      _chapters[chapterIndex]['learningPoints'].add(TextEditingController());
    });
  }

  void _deleteLearningPoint(int chapterIndex, int index) {
    if (_chapters[chapterIndex]['learningPoints'].length > 1) {
      setState(() {
        _chapters[chapterIndex]['learningPoints'].removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("At least one learning point is required.")),
      );
    }
  }

  // Upload Video to Cloudinary
  Future<Map<String, dynamic>?> uploadVideoToCloudinary(File videoFile) async {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/video/upload");

    var request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", videoFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(responseData);
      return {
        "url": jsonResponse["secure_url"],
        "duration": jsonResponse["duration"]
      };
    } else {
      print("Upload failed: ${response.statusCode} - $responseData");
      return null;
    }
  }

  // Upload File to Cloudinary (Document/Image)
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

  // Get video duration locally
  Future<double> getVideoDuration(File videoFile) async {
    VideoPlayerController controller = VideoPlayerController.file(videoFile);
    await controller.initialize();
    double duration = controller.value.duration.inSeconds.toDouble();
    controller.dispose();
    return duration;
  }

  Future<void> _pickVideo(int chapterIndex) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      File selectedVideo = File(result.files.first.path!);
      setState(() {
        _chapters[chapterIndex]['isUploading'] = true;
        _isUploadingVideo = true;
      });

      // Get duration locally
      double localDuration = await getVideoDuration(selectedVideo);

      // Upload video to Cloudinary
      Map<String, dynamic>? uploadResult =
          await uploadVideoToCloudinary(selectedVideo);

      setState(() {
        _chapters[chapterIndex]['uploadedVideo'] =
            uploadResult != null ? uploadResult["url"] : null;
        _chapters[chapterIndex]['videoDuration'] = uploadResult != null
            ? uploadResult["duration"] ?? localDuration
            : null;
        _chapters[chapterIndex]['isUploading'] = false;
        _isUploadingVideo = false;
      });

      if (uploadResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video upload failed! Try again.")),
        );
      }
    }
  }

  Future<void> _pickFiles(int chapterIndex) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _chapters[chapterIndex]['isUploading'] = true;
        _isUploadingFiles = true; // Set files uploading flag
      });

      List<File> filesToUpload = [];
      for (var file in result.files) {
        File selectedFile = File(file.path!);
        filesToUpload.add(selectedFile);
      }

      // Upload each file to Cloudinary and collect URLs
      for (var file in filesToUpload) {
        String? fileUrl = await uploadFileToCloudinary(file);
        if (fileUrl != null) {
          setState(() {
            _chapters[chapterIndex]['uploadedFiles']
                .add(fileUrl); // Store URL instead of file object
          });
        }
      }

      setState(() {
        _chapters[chapterIndex]['isUploading'] = false;
        _isUploadingFiles = false;
      });
    }
  }

  void _deleteVideo(int chapterIndex) {
    setState(() {
      _chapters[chapterIndex]['uploadedVideo'] = null;
      _chapters[chapterIndex]['videoDuration'] = null;
    });
  }

  Future<void> _submit() async {
    bool isValid = true;

    for (var chapter in _chapters) {
      if (chapter['titleController'].text.isEmpty ||
          chapter['descriptionController'].text.isEmpty) {
        isValid = false;
        break;
      }
      for (var learningPoint in chapter['learningPoints']) {
        if (learningPoint.text.isEmpty) {
          isValid = false;
          break;
        }
      }
    }

    if (isValid) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });

      for (var i = 0; i < _chapters.length; i++) {
        setState(() {
          _uploadProgress = (i + 1) / _chapters.length * 100;
        });

        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('chapters')
            .doc('${i + 1}')
            .set({
          'chapter_index': i + 1,
          'chapter_title': _chapters[i]['titleController'].text,
          'chapter_description': _chapters[i]['descriptionController'].text,
          'chapter_uploadedVideo': _chapters[i]['uploadedVideo'] ?? '',
          'chapter_videoDuration': _chapters[i]['videoDuration'] ?? 0,
          'chapter_learningPoints': _chapters[i]['learningPoints']
              .map((controller) => controller.text)
              .toList(),
          'chapter_uploadedFiles': _chapters[i]['uploadedFiles'].toList(),
        });
      }

      setState(() {
        _isLoading = false;
        _uploadProgress = 100.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chapters uploaded successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationMenu()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        appBar: AppBar(title: const Text("Add Chapters")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                for (int i = 0; i < _chapters.length; i++)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chapter ${i + 1}",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Text(
                        "Chapter Title ",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextFormField(
                        controller: _chapters[i]['titleController'],
                        decoration: InputDecoration(
                          labelText: "Chapter Title",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        maxLines: null, // This will allow unlimited lines
                        keyboardType:
                            TextInputType.multiline, // Allows multiline input
                        textInputAction: TextInputAction.newline,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Chapter Description ",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextFormField(
                        controller: _chapters[i]['descriptionController'],
                        decoration: InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "What You Will Learn ? ",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      for (int index = 0;
                          index < _chapters[i]['learningPoints'].length;
                          index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _chapters[i]['learningPoints']
                                      [index],
                                  decoration: InputDecoration(
                                    labelText: "Enter Point",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                  maxLines:
                                      null, // This will allow unlimited lines
                                  keyboardType: TextInputType
                                      .multiline, // Allows multiline input
                                  textInputAction: TextInputAction.newline,
                                ),
                              ),
                              if (_chapters[i]['learningPoints'].length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteLearningPoint(i, index),
                                ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      Center(
                          child: ElevatedButton(
                              onPressed: () => _addLearningPoint(i),
                              child: const Icon(Icons.add))),
                      Text("Upload Video",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      Center(
                        child: ElevatedButton(
                          onPressed: _chapters[i]['uploadedVideo'] == null ||
                                  _chapters[i]['uploadedVideo']!.isEmpty
                              ? () => _pickVideo(
                                  i) // Enable the button only if no video is uploaded
                              : null, // Disable the button if a video is uploaded
                          child: Text(
                            _chapters[i]['uploadedVideo'] == null ||
                                    _chapters[i]['uploadedVideo']!.isEmpty
                                ? "Select Video"
                                : "Video Already Uploaded", // Change text if video is uploaded
                          ),
                        ),
                      ),

                      if (_chapters[i]['uploadedVideo'] != null)
                        Row(
                          children: [
                            Column(
                              children: [
                                Text(
                                  "Video: ${_chapters[i]['uploadedVideo']!.split('/').last}",
                                  softWrap: true,
                                ),
                                Text(
                                  "Duration: ${_chapters[i]['videoDuration']} sec",
                                  softWrap: true,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteVideo(i),
                            ),
                          ],
                        ),
                      if (_isUploadingVideo)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      Text("Upload Files",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => _pickFiles(i),
                          child: Text(
                            _chapters[i]['uploadedFiles'].isEmpty
                                ? "Select Files"
                                : "Add More Files",
                          ),
                        ),
                      ),
                      if (_isUploadingFiles)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      // Inside the build method, within each chapter column
                      if (_chapters[i]['uploadedFiles'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Uploaded Files:"),
                            for (var fileUrl in _chapters[i]['uploadedFiles'])
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      Uri.parse(fileUrl)
                                          .pathSegments
                                          .last, // Extract the file name from the URL
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _chapters[i]['uploadedFiles']
                                            .remove(fileUrl);
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),

                      const Divider(),
                    ],
                  ),
                ElevatedButton(
                    onPressed: _addChapter,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(Colors.deepPurple),
                      foregroundColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 255, 255, 255)),
                      padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30)), // Increased padding
                    ),
                    child: const Text("Add Another Chapter")),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: _submit, child: const Text("Submit")),
                ),
                SizedBox(
                  height: 25,
                )
              ],
            ),
          ),
        ),
      ),
      if (_isLoading)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: _uploadProgress / 100),
                    Text("${_uploadProgress.toStringAsFixed(2)}%"),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
