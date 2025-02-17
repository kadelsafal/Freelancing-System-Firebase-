import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/courseDetail.dart';

class MyCourses extends StatefulWidget {
  const MyCourses({super.key});

  @override
  State<MyCourses> createState() => _MyCoursesState();
}

class _MyCoursesState extends State<MyCourses> {
  List<Map<String, dynamic>> myCourses = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchMyCourses();
  }

  Widget _getCourseTypeIcon(String courseType) {
    switch (courseType) {
      case 'Web Development':
        return const Icon(Icons.computer, size: 50, color: Colors.blue);
      case 'Mobile App Development':
        return const Icon(Icons.phone_android, size: 50, color: Colors.green);
      case 'Graphic Design & Multimedia':
        return const Icon(Icons.photo, size: 50, color: Colors.purple);
      case 'Digital Marketing':
        return const Icon(Icons.ads_click, size: 50, color: Colors.orange);
      case 'Data Science & Machine Learning':
        return const Icon(Icons.data_usage, size: 50, color: Colors.teal);
      case 'Writing & Content Creation':
        return const Icon(Icons.edit, size: 50, color: Colors.red);
      case 'Business & Entrepreneurship':
        return const Icon(Icons.business, size: 50, color: Colors.blueGrey);
      case 'Cybersecurity':
        return const Icon(Icons.security, size: 50, color: Colors.black);
      case 'Cloud Computing & DevOps':
        return const Icon(Icons.cloud, size: 50, color: Colors.blueAccent);
      case 'Translation & Language Services':
        return const Icon(Icons.language, size: 50, color: Colors.pink);
      default:
        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Image.asset(
            'assets/images/3950.jpg', // Default image for "Others"
            fit: BoxFit.cover,
            height: 100,
            width: double.infinity,
          ),
        );
    }
  }

  Future<void> fetchMyCourses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      userId = user.uid;

      var userCoursesSnapshot = await FirebaseFirestore.instance
          .collection('user_courses')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      List<String> courseIds = userCoursesSnapshot.docs
          .map((doc) => doc['courseId'] as String)
          .toList();

      if (courseIds.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      var courseSnapshots = await FirebaseFirestore.instance
          .collection('courses')
          .where(FieldPath.documentId, whereIn: courseIds)
          .get();

      List<Map<String, dynamic>> fetchedCourses =
          courseSnapshots.docs.map((doc) {
        var data = doc.data();
        data['courseId'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          myCourses = fetchedCourses;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching my courses: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myCourses.isEmpty
              ? const Center(
                  child: Text("You haven't enrolled in any courses yet."))
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two courses per row
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.7, // Adjust the aspect ratio
                    ),
                    itemCount: myCourses.length,
                    itemBuilder: (context, index) {
                      var course = myCourses[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to CourseDetail page when a course is clicked
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseDetail(
                                courseId: course['courseId'],
                                title: course['title'] ?? 'Course',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  color: Colors.grey[200],
                                ),
                                child: Center(
                                    child: _getCourseTypeIcon(
                                        course['courseType'] ?? 'Others')),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Instructor: ${course['username'] ?? 'Unknown'}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 34,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          "Paid",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
