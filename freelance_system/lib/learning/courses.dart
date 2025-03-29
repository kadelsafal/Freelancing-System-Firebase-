import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/learning/addcourse.dart';
import 'package:freelance_system/learning/courseDetail.dart';
import 'package:freelance_system/learning/editCourse.dart';

class Courses extends StatefulWidget {
  const Courses({super.key});

  @override
  State<Courses> createState() => _CoursesState();
}

class _CoursesState extends State<Courses> {
  List<Map<String, dynamic>> courses = [];
  bool isLoading = true;

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

  // Function to fetch courses based on current user
  Future<void> fetchMyCourses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      String userId = user.uid;

      // Fetch courses where username or userId matches
      var courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('userId', isEqualTo: userId) // Match with current user's ID
          .get();

      List<Map<String, dynamic>> fetchedCourses =
          courseSnapshot.docs.map((doc) {
        var data = doc.data();
        data['courseId'] = doc.id; // Include the course ID
        return data;
      }).toList();

      setState(() {
        courses = fetchedCourses;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching courses: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Course"),
        toolbarHeight: 120,
        backgroundColor: Colors.deepPurple,
        foregroundColor:
            Colors.white, // Set the background color to deep purple
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
              ? const Center(
                  child: Text("You haven't enrolled in any courses yet."))
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 250,
                          child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Addcourse()));
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(Colors.deepPurple),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Add Course",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(
                                      width: 3,
                                    ),
                                    Icon(
                                      Icons.menu_book_outlined,
                                      color: Colors.white,
                                      size: 40,
                                    )
                                  ],
                                ),
                              )),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Uploaded Course",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Two courses per row
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.7, // Adjust the aspect ratio
                          ),
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            var course = courses[index];
                            return GestureDetector(
                              onTap: () {
                                // Navigate to CourseDetail page when a course is clicked
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Editcourse(
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
                                              course['courseType'] ??
                                                  'Others')),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course['title'] ?? 'No Title',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: null,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Instructor: ${course['username'] ?? 'Unknown'}",
                                            maxLines: null,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {},
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.all(
                                                          Colors.deepPurple),
                                                  foregroundColor:
                                                      WidgetStateProperty.all(
                                                          const Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255)),
                                                  padding: WidgetStateProperty
                                                      .all(EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal:
                                                              20)), // Increased padding
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        size: 24,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        "Edit",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: const Color
                                                                .fromARGB(255,
                                                                255, 255, 255)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                    ],
                  ),
                ),
    );
  }
}
