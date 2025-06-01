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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/admin/coursescreen.dart';

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
      'localFiles': <File>[],
      'uploadedVideo': null,
      'localVideoFile': null,
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
        'localFiles': <File>[],
        'uploadedVideo': null,
        'localVideoFile': null,
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
        // Only store the local video file for preview
        _chapters[chapterIndex]['localVideoFile'] = selectedVideo;
        _chapters[chapterIndex]['uploadedVideo'] =
            null; // Clear any previous upload
        _chapters[chapterIndex]['isUploading'] = false;
      });
      try {
        // Get duration locally
        double localDuration = await getVideoDuration(selectedVideo);
        setState(() {
          _chapters[chapterIndex]['videoDuration'] = localDuration;
        });
      } catch (e) {
        setState(() {
          _chapters[chapterIndex]['videoDuration'] = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing video: $e")),
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
        _chapters[chapterIndex]['isUploading'] = false;
      });
      List<File> filesToAdd = [];
      for (var file in result.files) {
        File selectedFile = File(file.path!);
        filesToAdd.add(selectedFile);
      }
      setState(() {
        _chapters[chapterIndex]['localFiles'].addAll(filesToAdd);
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

    // Validate chapters and learning points (ignore empty controllers)
    for (var chapter in _chapters) {
      if (chapter['titleController'].text.isEmpty ||
          chapter['descriptionController'].text.isEmpty) {
        isValid = false;
        break;
      }
      // Only consider non-empty learning points
      final nonEmptyPoints =
          (chapter['learningPoints'] as List<TextEditingController>)
              .where((controller) => controller.text.trim().isNotEmpty)
              .toList();
      if (nonEmptyPoints.isEmpty) {
        isValid = false;
        break;
      }
    }

    if (isValid) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });

      // Calculate total uploads (videos + files)
      double totalUploads = 0;
      for (var chapter in _chapters) {
        if (chapter['localVideoFile'] != null &&
            chapter['uploadedVideo'] == null) {
          totalUploads++;
        }
        if (chapter['localFiles'] != null) {
          totalUploads += chapter['localFiles'].length;
        }
      }
      double completedUploads = 0;

      for (var i = 0; i < _chapters.length; i++) {
        // Upload video to Cloudinary if not already uploaded
        if (_chapters[i]['localVideoFile'] != null &&
            _chapters[i]['uploadedVideo'] == null) {
          setState(() {
            _chapters[i]['isUploading'] = true;
          });
          Map<String, dynamic>? uploadResult =
              await uploadVideoToCloudinary(_chapters[i]['localVideoFile']);
          if (uploadResult != null) {
            _chapters[i]['uploadedVideo'] = uploadResult["url"];
            _chapters[i]['videoDuration'] =
                uploadResult["duration"] ?? _chapters[i]['videoDuration'];
          } else {
            setState(() {
              _chapters[i]['isUploading'] = false;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Video upload failed for Chapter ${i + 1}! Try again.")),
            );
            return;
          }
          completedUploads++;
          setState(() {
            _chapters[i]['isUploading'] = false;
            _uploadProgress = (completedUploads / totalUploads) * 100;
          });
        }
        // Upload files to Cloudinary if not already uploaded
        if (_chapters[i]['localFiles'] != null &&
            _chapters[i]['localFiles'].isNotEmpty) {
          setState(() {
            _chapters[i]['isUploading'] = true;
          });
          List<String> uploadedFileUrls = [];
          for (var file in _chapters[i]['localFiles']) {
            String? fileUrl = await uploadFileToCloudinary(file);
            if (fileUrl != null) {
              uploadedFileUrls.add(fileUrl);
            } else {
              setState(() {
                _chapters[i]['isUploading'] = false;
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "File upload failed for Chapter ${i + 1}! Try again.")),
              );
              return;
            }
            completedUploads++;
            setState(() {
              _uploadProgress = (completedUploads / totalUploads) * 100;
            });
          }
          _chapters[i]['uploadedFiles'] = uploadedFileUrls;
          setState(() {
            _chapters[i]['isUploading'] = false;
          });
        }
        // Save only non-empty learning points
        final nonEmptyPoints =
            (_chapters[i]['learningPoints'] as List<TextEditingController>)
                .where((controller) => controller.text.trim().isNotEmpty)
                .map((controller) => controller.text.trim())
                .toList();
        setState(() {
          _uploadProgress = totalUploads == 0
              ? 100.0
              : (completedUploads / totalUploads) * 100;
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
          'chapter_learningPoints': nonEmptyPoints,
          'chapter_uploadedFiles': _chapters[i]['uploadedFiles'],
        });
        // After upload, clear localFiles
        _chapters[i]['localFiles'] = [];
      }

      setState(() {
        _isLoading = false;
        _uploadProgress = 100.0;
      });
      await Future.delayed(const Duration(milliseconds: 100)); // Let UI update

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chapters uploaded successfully!")),
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == 'admin@gmail.com') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CourseScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationMenu(initialIndex: 3)),
          (route) => false,
        );
      }
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
        appBar: AppBar(
          title: const Text("Add Chapters"),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1565C0), Colors.white],
              stops: [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                for (int i = 0; i < _chapters.length; i++)
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1565C0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Chapter ${i + 1}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                              if (i > 0)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _chapters.removeAt(i);
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _chapters[i]['titleController'],
                            decoration: InputDecoration(
                              labelText: "Chapter Title",
                              prefixIcon: const Icon(Icons.title,
                                  color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFF1565C0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1565C0), width: 2),
                              ),
                            ),
                            maxLines: null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _chapters[i]['descriptionController'],
                            decoration: InputDecoration(
                              labelText: "Description",
                              prefixIcon: const Icon(Icons.description,
                                  color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFF1565C0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1565C0), width: 2),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Learning Points",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller:
                                      _chapters[i]['learningPoints'].last,
                                  decoration: InputDecoration(
                                    hintText: "Add a learning point",
                                    prefixIcon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF1565C0)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF1565C0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: const Color(0xFF1565C0)
                                              .withOpacity(0.5)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF1565C0), width: 2),
                                    ),
                                  ),
                                  onFieldSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      _addLearningPoint(i);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Color(0xFF1565C0)),
                                onPressed: () {
                                  if (_chapters[i]['learningPoints']
                                      .last
                                      .text
                                      .isNotEmpty) {
                                    _addLearningPoint(i);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (int j = 0;
                                  j < _chapters[i]['learningPoints'].length - 1;
                                  j++)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF1565C0)
                                            .withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Color(0xFF1565C0), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _chapters[i]['learningPoints'][j].text,
                                        style: const TextStyle(
                                            color: Color(0xFF1565C0)),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _deleteLearningPoint(i, j),
                                        child: const Icon(Icons.close,
                                            color: Colors.red, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Video Content",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _chapters[i]['isUploading']
                                  ? null
                                  : () => _pickVideo(i),
                              icon: Icon(
                                _chapters[i]['uploadedVideo'] == null
                                    ? Icons.video_library
                                    : Icons.check_circle,
                                color: Colors.white,
                              ),
                              label: Text(
                                _chapters[i]['uploadedVideo'] == null
                                    ? (_chapters[i]['isUploading']
                                        ? "Uploading..."
                                        : "Select Video")
                                    : "Video Uploaded",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_chapters[i]['isUploading'])
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1565C0)),
                                ),
                              ),
                            ),
                          if (_chapters[i]['localVideoFile'] != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.video_file,
                                                  color: Color(0xFF1565C0),
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _chapters[i]['localVideoFile']
                                                          ?.path
                                                          .split('/')
                                                          .last ??
                                                      'Video',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteVideo(i),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_chapters[i]['uploadedVideo'] == null)
                                    Text(
                                      "Video not uploaded yet",
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (_chapters[i]['uploadedVideo'] != null)
                                    Text(
                                      "Video uploaded successfully",
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (_chapters[i]['videoDuration'] != null)
                                    Text(
                                      "Duration: " +
                                          _formatDuration(
                                              _chapters[i]['videoDuration']),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            "Additional Files",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickFiles(i),
                              icon: const Icon(Icons.attach_file,
                                  color: Colors.white),
                              label: Text(
                                _chapters[i]['uploadedFiles'].isEmpty
                                    ? "Select Files"
                                    : "Add More Files",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_chapters[i]['localFiles'] != null &&
                              _chapters[i]['localFiles'].isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                for (var file in _chapters[i]['localFiles'])
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.insert_drive_file,
                                            color: Color(0xFF1565C0)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            file.path.split('/').last,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _chapters[i]['localFiles']
                                                  .remove(file);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _addChapter,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Another Chapter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Submit All Chapters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
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
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${_uploadProgress.toStringAsFixed(2)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  String _formatDuration(double seconds) {
    final int totalSeconds = seconds.round();
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int secs = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
