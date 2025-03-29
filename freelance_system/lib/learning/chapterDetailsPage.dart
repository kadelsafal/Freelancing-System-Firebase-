import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class ChapterDetailsPage extends StatefulWidget {
  final String courseId;
  final int chapterId;

  const ChapterDetailsPage(
      {super.key, required this.courseId, required this.chapterId});

  @override
  State<ChapterDetailsPage> createState() => _ChapterDetailsPageState();
}

class _ChapterDetailsPageState extends State<ChapterDetailsPage> {
  Map<String, dynamic>? chapterData;
  late VideoPlayerController _videoPlayerController;
  late CustomVideoPlayerController _customVideoPlayerController;
  bool _isLoading = true;
  String? _videoUrl;
  double? _videoDuration;

  @override
  void initState() {
    super.initState();
    fetchChapterDetails();
  }

  Future<void> fetchChapterDetails() async {
    try {
      var chapterSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('chapters')
          .doc(widget.chapterId.toString())
          .get();

      if (chapterSnapshot.exists) {
        setState(() {
          chapterData = chapterSnapshot.data();
          _isLoading = false;
        });
        String? videoUrl = chapterSnapshot['chapter_uploadedVideo'];
        double? videoDuration = chapterSnapshot['chapter_videoDuration'];

        if (videoUrl != null && videoUrl.isNotEmpty) {
          setState(() {
            _videoUrl = videoUrl;
            _videoDuration = videoDuration;
            _initializeVideoPlayer();
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching chapter details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    if (_videoUrl != null) {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(_videoUrl!))
            ..initialize().then((_) {
              setState(() {
                _isLoading = false;
              });
            })
            ..addListener(() {
              setState(() {});
            });

      _customVideoPlayerController = CustomVideoPlayerController(
        context: context,
        videoPlayerController: _videoPlayerController,
      );
    }
  }

  @override
  void dispose() {
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chapter ${widget.chapterId} Details',
          style: TextStyle(color: Colors.white), // Ensures title text is white
        ),
        backgroundColor:
            Colors.deepPurple, // Sets background color to deep purple
        iconTheme: IconThemeData(color: Colors.white),
        toolbarHeight: 100, // Ensures back icon is white
      ),
      body: Stack(
        children: [
          _isLoading
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'Loading video...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : chapterData == null
                  ? const Center(child: Text("Chapter not found"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 30,
                          ),
                          Text(
                            "${chapterData!["chapter_title"] ?? 'No Title'}",
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple),
                            softWrap: true,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 250, // Adjust height as needed
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  16), // Adjust radius as needed
                              child: CustomVideoPlayer(
                                customVideoPlayerController:
                                    _customVideoPlayerController,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                          // Directly displaying the description below the video
                          if (chapterData!["chapter_description"] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                chapterData!["chapter_description"] ??
                                    "No description available",
                                textAlign: TextAlign.justify,
                                style: const TextStyle(fontSize: 16),
                                softWrap: true,
                              ),
                            ),
                          const SizedBox(height: 20),
                          // Display learning points
                          if (chapterData!["chapter_learningPoints"] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "What You Will Learn ?",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                ),
                                const SizedBox(height: 10),
                                ...List.generate(
                                  (chapterData!["chapter_learningPoints"]
                                          as List)
                                      .length,
                                  (index) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Text("• ",
                                            style: TextStyle(fontSize: 16)),
                                        Expanded(
                                          child: Text(
                                            chapterData![
                                                    "chapter_learningPoints"]
                                                [index],
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          // Display uploaded files with their names
                          if (chapterData!["chapter_uploadedFiles"] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Uploaded Files",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                ),
                                const SizedBox(height: 10),
                                ...List.generate(
                                  (chapterData!["chapter_uploadedFiles"]
                                          as List)
                                      .length,
                                  (index) => ListTile(
                                    leading: const Icon(Icons.attach_file),
                                    title: Text(
                                      "File ${index + 1}: ${Uri.parse(chapterData!["chapter_uploadedFiles"][index]).pathSegments.last}",
                                    ),
                                    onTap: () async {
                                      final url =
                                          chapterData!["chapter_uploadedFiles"]
                                              [index];
                                      if (await canLaunch(url)) {
                                        await launch(url);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text("Could not open file."),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 30),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
