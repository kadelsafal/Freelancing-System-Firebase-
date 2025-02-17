import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/learning/coursecard.dart'; // Import the updated CourseCard widget

class Allcourses extends StatefulWidget {
  const Allcourses({super.key});

  @override
  State<Allcourses> createState() => _AllcoursesState();
}

class _AllcoursesState extends State<Allcourses> {
  final CollectionReference coursesCollection =
      FirebaseFirestore.instance.collection('courses');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[200], // Light background
        body: StreamBuilder<QuerySnapshot>(
          stream: coursesCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No courses available"));
            }

            final courses = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  var course = courses[index].data() as Map<String, dynamic>;

                  // Add checks to ensure all fields exist
                  String title = course['title'] ?? "No Title";
                  String courseType = course["courseType"] ?? "Others";
                  double price = course['price']?.toDouble() ?? 0.0;
                  int currentAppliedUsers = course["appliedUsers"] ?? 0;
                  String courseId = course["courseId"];
                  return CourseCard(
                    CourseId: courseId,
                    title: title,
                    courseType: courseType,
                  );
                },
              ),
            );
          },
        ));
  }
}
