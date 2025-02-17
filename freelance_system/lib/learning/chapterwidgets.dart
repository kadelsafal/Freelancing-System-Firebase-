import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chapterDetailsPage.dart';

class ChaptersWidget extends StatefulWidget {
  final String courseId;
  final List<Map<String, dynamic>> chapters;
  final bool isPaid;
  const ChaptersWidget({
    super.key,
    required this.courseId,
    required this.chapters,
    required this.isPaid,
  });

  @override
  _ChaptersWidgetState createState() => _ChaptersWidgetState();
}

class _ChaptersWidgetState extends State<ChaptersWidget> {
  // Keeps track of which chapter is expanded (for description and details)
  List<bool> _expandedChapters = [];

  @override
  void initState() {
    super.initState();
    // Initialize _expandedChapters with false (no chapter is expanded by default)
    _expandedChapters = List.generate(widget.chapters.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Chapters",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            widget.isPaid
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_sharp,
                        color: Color.fromARGB(255, 255, 113, 25),
                        size: 30,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Enrolled",
                        style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 255, 113, 25)),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Locked",
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ],
                  ),
          ],
        ),
        const SizedBox(height: 20),
        widget.chapters.isEmpty
            ? Center(
                child: const Text(
                  "No chapters available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.chapters.length,
                itemBuilder: (context, index) {
                  var chapter = widget.chapters[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedChapters[index] = !_expandedChapters[index];
                      });
                      if (widget.isPaid) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChapterDetailsPage(
                              courseId: widget.courseId,
                              chapterId: chapter['chapterNumber'],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.deepPurple.withOpacity(0.1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display Chapter Index and Title
                          Text(
                            "Chapter ${chapter['chapterNumber']}: ${chapter['chapter_title']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Display description and details if the chapter is expanded
                          if (_expandedChapters[index]) ...[
                            const Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chapter['chapter_description'] ??
                                  "No description available",
                              textAlign: TextAlign.justify,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 25),

                            // Benefits as Bullet Points
                            if (chapter['chapter_learningPoints'] != null &&
                                (chapter['chapter_learningPoints'] as List)
                                    .isNotEmpty) ...[
                              const Text(
                                "What you will Learn?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: (chapter['chapter_learningPoints']
                                        as List)
                                    .map<Widget>((learningPoint) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                "• ",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  learningPoint,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],

                          // Lock/Unlock icon and status text
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
