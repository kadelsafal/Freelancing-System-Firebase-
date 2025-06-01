import 'package:flutter/material.dart';
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            widget.isPaid
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_sharp,
                        color: Color(0xFF1976D2),
                        size: 26,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Enrolled",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Locked",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF1976D2)),
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
                  style: TextStyle(fontSize: 16, color: Color(0xFF1976D2)),
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
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border:
                            Border.all(color: Color(0xFF1976D2), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1976D2),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Chapter ${chapter['chapterNumber']}: ${chapter['chapter_title']}",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _expandedChapters[index]
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Description",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      chapter['chapter_description'] ??
                                          "No description available",
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1976D2)),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (chapter['chapter_learningPoints'] !=
                                          null &&
                                      (chapter['chapter_learningPoints']
                                              as List)
                                          .isNotEmpty) ...[
                                    const Text(
                                      "What you will Learn?",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: (chapter[
                                              'chapter_learningPoints'] as List)
                                          .map<Widget>((point) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 2),
                                                child: Row(
                                                  children: [
                                                    const Text("• ",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xFF1976D2))),
                                                    Expanded(
                                                      child: Text(point,
                                                          style: const TextStyle(
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xFF1976D2))),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            crossFadeState: _expandedChapters[index]
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 250),
                          ),
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
