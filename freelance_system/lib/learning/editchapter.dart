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
  final String? posterUrl;
  const EditChapter({super.key, required this.courseId, this.posterUrl});

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
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['chapter_title'] ?? '',
            'description': data['chapter_description'] ?? '',
            'learningPoints':
                List<String>.from(data['chapter_learningPoints'] ?? []),
            'uploadedFiles':
                List<String>.from(data['chapter_uploadedFiles'] ?? []),
            'uploadedVideo': data['chapter_uploadedVideo'],
            'videoDuration': data['chapter_videoDuration'],
            'videoFileName': data['videoFileName'],
          };
        }).toList();

        // Sort chapters by numeric id if possible
        _chapters.sort((a, b) {
          int aId = int.tryParse(a['id'] ?? '') ?? 9999;
          int bId = int.tryParse(b['id'] ?? '') ?? 9999;
          return aId.compareTo(bId);
        });

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
        'videoFileName': null,
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
          'videoFileName': _chapters[i]['videoFileName'],
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
        MaterialPageRoute(
            builder: (context) => const NavigationMenu(
                  initialIndex: 3,
                )),
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
        _chapters[index]['videoFileName'] = result.files.first.name;
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Chapters',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Course ID: ${widget.courseId}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Course Chapters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                            letterSpacing: 0.5,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addChapter,
                          icon: const Icon(Icons.add,
                              size: 20, color: Colors.white),
                          label: const Text('Add Chapter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(_chapters.length, (index) {
                      return _buildChapterCard(index);
                    }),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isUploadingFiles || _isUploadingVideo
                            ? null
                            : _saveChapters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isUploadingFiles || _isUploadingVideo
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChapterCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chapter ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _deleteChapter(index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _titleControllers[index],
                  label: 'Chapter Title',
                  hint: 'Enter chapter title',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionControllers[index],
                  label: 'Chapter Description',
                  hint: 'Enter chapter description',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                _buildLearningPointsSection(index),
                const SizedBox(height: 24),
                _buildFileUploadSection(index),
                const SizedBox(height: 24),
                _buildVideoUploadSection(index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }

  Widget _buildLearningPointsSection(int chapterIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Points',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _learningPointControllers[chapterIndex],
                  decoration: InputDecoration(
                    hintText: 'Add learning point',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: Color(0xFF1976D2), size: 28),
                      onPressed: () => _addLearningPoint(chapterIndex),
                    ),
                  ),
                  onFieldSubmitted: (_) => _addLearningPoint(chapterIndex),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_chapters[chapterIndex]['learningPoints'] as List<String>)
              .asMap()
              .entries
              .map((entry) => Chip(
                    label: Text(entry.value),
                    backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFF1976D2)),
                    deleteIconColor: const Color(0xFF1976D2),
                    onDeleted: () =>
                        _deleteLearningPoint(chapterIndex, entry.key),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection(int chapterIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supporting Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isUploadingFiles ? null : () => _uploadFile(chapterIndex),
          icon: const Icon(Icons.upload_file, color: Colors.white),
          label: const Text('Upload Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_chapters[chapterIndex]['uploadedFiles'].isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uploaded Files:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 8),
                ...(_chapters[chapterIndex]['uploadedFiles'] as List<String>)
                    .map((file) {
                  final fileName = file.split('/').last;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file,
                            size: 16, color: Color(0xFF1976D2)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoUploadSection(int chapterIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chapter Video',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed:
              _isUploadingVideo ? null : () => _uploadVideo(chapterIndex),
          icon: const Icon(Icons.video_library, color: Colors.white),
          label: const Text('Upload Video'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_chapters[chapterIndex]['uploadedVideo'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_file,
                    size: 16, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _chapters[chapterIndex]['videoFileName'] ??
                        _chapters[chapterIndex]['uploadedVideo']
                            .split('/')
                            .last,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_chapters[chapterIndex]['videoDuration'] != null)
                  Text(
                    ' (${_formatDuration((_chapters[chapterIndex]['videoDuration'] as num).toDouble())})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
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
