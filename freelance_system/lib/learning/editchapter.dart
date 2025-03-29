import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:freelance_system/screens/elearning.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditChapter extends StatefulWidget {
  final String courseId;
  const EditChapter({super.key, required this.courseId});

  @override
  State<EditChapter> createState() => _EditChapterState();
}

class _EditChapterState extends State<EditChapter> {
  List<Map<String, dynamic>> _chapters = [];
  List<TextEditingController> _titleControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<TextEditingController> _learningPointControllers = [];
  bool _isLoading = true;
  bool _isUploadingFiles = false;
  bool _isUploadingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  @override
  void dispose() {
    for (var controller in _titleControllers) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    for (var controller in _learningPointControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final courseRef =
          FirebaseFirestore.instance.collection('courses').doc(widget.courseId);
      final chapterSnapshot = await courseRef.collection('chapters').get();

      setState(() {
        _chapters = chapterSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc['chapter_title'] ?? '',
            'description': doc['chapter_description'] ?? '',
            'learningPoints':
                List<String>.from(doc['chapter_learningPoints'] ?? []),
            'uploadedFiles':
                List<String>.from(doc['chapter_uploadedFiles'] ?? []),
            'uploadedVideo': doc['chapter_uploadedVideo'],
            'videoDuration': doc['chapter_videoDuration'],
          };
        }).toList();

        _titleControllers = _chapters
            .map((chapter) => TextEditingController(text: chapter['title']))
            .toList();

        _descriptionControllers = _chapters
            .map((chapter) =>
                TextEditingController(text: chapter['description']))
            .toList();

        _learningPointControllers =
            List.generate(_chapters.length, (_) => TextEditingController());

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error loading chapters: $e");
    }
  }

  void _addChapter() {
    setState(() {
      _chapters.add({
        'title': '',
        'description': '',
        'learningPoints': <String>[],
        'uploadedFiles': <String>[],
        'uploadedVideo': null,
        'videoDuration': null,
      });

      _titleControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _learningPointControllers.add(TextEditingController());
    });
  }

  Future<void> _deleteChapter(int index) async {
    final chapterId = _chapters[index]['id'];

    // Delete uploaded files from Cloudinary
    try {
      final uploadedFiles = _chapters[index]['uploadedFiles'] as List<String>;
      for (var fileUrl in uploadedFiles) {
        await _deleteFileFromCloudinary(fileUrl);
      }

      // Delete uploaded video from Cloudinary
      if (_chapters[index]['uploadedVideo'] != null) {
        await _deleteFileFromCloudinary(_chapters[index]['uploadedVideo']);
      }

      // Delete the chapter document
      if (chapterId != null) {
        final courseRef = FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId);
        await courseRef.collection('chapters').doc(chapterId).delete();
      }

      // Remove the chapter data and clean up controllers
      setState(() {
        _chapters.removeAt(index);
        _titleControllers[index].dispose();
        _descriptionControllers[index].dispose();
        _learningPointControllers[index].dispose();
        _titleControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _learningPointControllers.removeAt(index);
      });
    } catch (e) {
      print("Error deleting chapter: $e");
    }
  }

  Future<void> _deleteFileFromCloudinary(String fileUrl) async {
    try {
      final publicId = fileUrl
          .split('/')
          .last
          .split('.')
          .first; // Extract public ID from the URL
      final uri = Uri.parse(
          "https://api.cloudinary.com/v1_1/$cloudName/resources/image/upload");

      var response = await http.delete(
        uri,
        body: json.encode({
          "public_ids": [publicId],
        }),
        headers: {
          "Authorization":
              "Basic ${base64Encode(utf8.encode('api:$uploadPreset'))}",
        },
      );

      if (response.statusCode == 200) {
        print("File deleted successfully from Cloudinary");
      } else {
        print("Failed to delete file from Cloudinary: ${response.statusCode}");
      }
    } catch (e) {
      print("Error deleting file from Cloudinary: $e");
    }
  }

  Future<void> _saveChapters() async {
    try {
      final courseRef =
          FirebaseFirestore.instance.collection('courses').doc(widget.courseId);

      for (int i = 0; i < _chapters.length; i++) {
        final chapterData = {
          'chapter_title': _titleControllers[i].text,
          'chapter_description': _descriptionControllers[i].text,
          'chapter_learningPoints': _chapters[i]['learningPoints'],
          'chapter_uploadedFiles': _chapters[i]['uploadedFiles'],
          'chapter_uploadedVideo': _chapters[i]['uploadedVideo'],
          'chapter_videoDuration': _chapters[i]['videoDuration'],
        };

        if (_chapters[i]['id'] == null) {
          // If chapter does not have an ID, create a new document in Firestore with index-based ID
          var docRef = await courseRef
              .collection('chapters')
              .doc('${i + 1}')
              .set(chapterData);

          setState(() {
            _chapters[i]['id'] =
                '${i + 1}'; // Save the generated ID (index-based) to the chapter object
          });
        } else {
          // If chapter has an ID, update the existing document
          await courseRef
              .collection('chapters')
              .doc(_chapters[i]['id'])
              .update(chapterData);
        }
      }

      // Optionally, you can show a success message or feedback to the user here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapters saved successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationMenu()),
      );
      // This will remove all previous routes
    } catch (e) {
      print("Error saving chapters: $e");
      // Optionally, you can show an error message or feedback to the user here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save chapters!')),
      );
    }
  }

  void _addLearningPoint(int chapterIndex) {
    if (_learningPointControllers[chapterIndex].text.isNotEmpty) {
      setState(() {
        _chapters[chapterIndex]['learningPoints']
            .add(_learningPointControllers[chapterIndex].text);
        _learningPointControllers[chapterIndex].clear();
      });
    }
  }

  void _deleteLearningPoint(int chapterIndex, int index) {
    setState(() {
      _chapters[chapterIndex]['learningPoints'].removeAt(index);
    });
  }

  void _uploadFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _isUploadingFiles = true;
      });

      for (var file in result.files) {
        File selectedFile = File(file.path!);
        String? fileUrl = await uploadFileToCloudinary(selectedFile);
        if (fileUrl != null) {
          setState(() {
            _chapters[index]['uploadedFiles'].add(fileUrl);
          });
        }
      }

      setState(() {
        _isUploadingFiles = false;
      });
    }
  }

  void _uploadVideo(int index) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _isUploadingVideo = true;
      });

      File selectedVideo = File(result.files.first.path!);
      Map<String, dynamic>? uploadResult =
          await uploadVideoToCloudinary(selectedVideo);

      setState(() {
        _chapters[index]['uploadedVideo'] = uploadResult?['url'];
        _chapters[index]['videoDuration'] = uploadResult?['duration'] ?? 0;
        _isUploadingVideo = false;
      });
    }
  }

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

  void _deleteFile(int chapterIndex, int fileIndex) {
    setState(() {
      _chapters[chapterIndex]['uploadedFiles'].removeAt(fileIndex);
    });
  }

  void _deleteVideo(int chapterIndex) {
    setState(() {
      _chapters[chapterIndex]['uploadedVideo'] = null;
      _chapters[chapterIndex]['videoDuration'] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          title: const Text("Edit Chapters"),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                size: 45,
                color: Colors.deepPurple,
              ),
              onPressed: _saveChapters,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    for (int i = 0; i < _chapters.length; i++) ...[
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Chapter ${i + 1}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple)),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteChapter(i),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text('Title',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Chapter Title',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _titleControllers[i],
                                maxLines: null,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text('Description',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _descriptionControllers[i],
                                maxLines: null,
                              ),
                              const SizedBox(height: 30),

                              Text('What will You Learn ?',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),

                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: _learningPointControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Enter Learning Point',
                                  border: OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.deepPurple,
                                      size: 40,
                                    ),
                                    onPressed: () => _addLearningPoint(i),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8.0,
                                children: _chapters[i]['learningPoints']
                                    .map<Widget>((point) => Chip(
                                          label: Text(point),
                                          deleteIcon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red),
                                          onDeleted: () => _deleteLearningPoint(
                                              i,
                                              _chapters[i]['learningPoints']
                                                  .indexOf(point)),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 30),
                              Text('Upload Files ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),

                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _uploadFile(i),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                        Colors.deepPurple),
                                    foregroundColor:
                                        WidgetStateProperty.all(Colors.white),
                                  ),
                                  child: _isUploadingFiles
                                      ? CircularProgressIndicator()
                                      : const Text("Upload File"),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Display uploaded files
                              _chapters[i]['uploadedFiles'].isNotEmpty
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Uploaded Files:'),
                                        const SizedBox(height: 5),
                                        for (int j = 0;
                                            j <
                                                _chapters[i]['uploadedFiles']
                                                    .length;
                                            j++) ...[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.file_open,
                                                    size: 30,
                                                    color:
                                                        Colors.deepPurpleAccent,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "${_chapters[i]['uploadedFiles'][j].split('/').last}",
                                                    softWrap: true,
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteFile(i, j),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                        ],
                                      ],
                                    )
                                  : const SizedBox(),

                              const SizedBox(height: 30),

                              Text('Upload Video ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),

                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _chapters[i]['uploadedVideo'] !=
                                              null ||
                                          _isUploadingVideo
                                      ? () {
                                          // Show a snack bar when trying to upload a second video
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'You can upload only one video per chapter.'),
                                            ),
                                          );
                                        } // Disable the button if video is uploaded or uploading
                                      : () => _uploadVideo(i),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _chapters[i]
                                                ['uploadedVideo'] !=
                                            null
                                        ? Colors
                                            .grey // Change color to grey if video is uploaded
                                        : Colors
                                            .deepPurple, // Default color when it's not uploaded
                                  ),
                                  // Enable if no video is uploaded

                                  child: _isUploadingVideo
                                      ? const CircularProgressIndicator()
                                      : const Text(
                                          "Upload Video",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Display uploaded video
                              _chapters[i]['uploadedVideo'] != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Uploaded Video:'),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .video_collection_outlined,
                                                  size: 30,
                                                  color:
                                                      Colors.deepPurpleAccent,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  " ${_chapters[i]['uploadedVideo']!.split('/').last}",
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () => _deleteVideo(i),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ],
                    ElevatedButton(
                      onPressed: _addChapter,
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.deepPurple),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      child: const Text("Add New Chapter"),
                    ),
                  ],
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
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
