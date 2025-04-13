import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Course Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching courses.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          final courses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final courseData = course.data() as Map<String, dynamic>;

              final title = courseData['title'] ?? 'Untitled';
              final description = courseData['description'] ?? '';
              final courseType = courseData['courseType'] ?? 'Unknown';
              final price = courseData['price'] ?? 0;
              final skills = List<String>.from(courseData['skills'] ?? []);
              final benefits = List<String>.from(courseData['benefits'] ?? []);
              final username = courseData['username'] ?? 'Unknown';
              final appliedUsers = courseData['appliedUsers'] ?? 0;

              return FutureBuilder<QuerySnapshot>(
                future: course.reference
                    .collection('chapters')
                    .orderBy('chapter_index')
                    .get(),
                builder: (context, chapterSnapshot) {
                  if (chapterSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chapters = chapterSnapshot.data?.docs ?? [];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text("Instructor: $username"),
                          const SizedBox(height: 6),
                          Text("Course Type: $courseType"),
                          const SizedBox(height: 6),
                          Text("Price: Rs. $price"),
                          const SizedBox(height: 6),
                          Text("Applied Users: $appliedUsers"),
                          const Divider(height: 20),
                          Text("Description:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(description),
                          const SizedBox(height: 10),
                          Text("Skills Covered:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 6,
                            runSpacing: -8,
                            children: skills
                                .map((s) => Chip(label: Text(s)))
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                          Text("Benefits:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...benefits.map((b) => Text("• $b")),
                          const Divider(height: 30),
                          Text("Chapters (${chapters.length}):",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...chapters.map((chapterDoc) {
                            final data =
                                chapterDoc.data() as Map<String, dynamic>;
                            final chapterTitle = data['chapter_title'] ?? '';
                            final chapterIndex = data['chapter_index'] ?? '';
                            final chapterDescription =
                                data['chapter_description'] ?? '';
                            final learningPoints = List<String>.from(
                                data['chapter_learningPoints'] ?? []);
                            final uploadedFiles = List<String>.from(
                                data['chapter_uploadedFiles'] ?? []);
                            final uploadedVideo =
                                data['chapter_uploadedVideo'] ?? '';
                            final videoDuration = data['chapter_videoDuration']
                                    ?.toStringAsFixed(2) ??
                                '0.0';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Chapter $chapterIndex: $chapterTitle",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text("Description: $chapterDescription"),
                                  const SizedBox(height: 4),
                                  Text("Learning Points:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  ...learningPoints
                                      .map((point) => Text("• $point")),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Video Duration: $videoDuration seconds"),
                                  if (uploadedVideo.isNotEmpty)
                                    Text("Video: $uploadedVideo",
                                        style: const TextStyle(
                                            color: Colors.blue)),
                                  if (uploadedFiles.isNotEmpty)
                                    Text("Files:",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ...uploadedFiles.map((file) => Text(file,
                                      style:
                                          const TextStyle(color: Colors.blue))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
