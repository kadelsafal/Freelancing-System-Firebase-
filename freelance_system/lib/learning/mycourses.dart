import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/courseDetail.dart';
import 'package:freelance_system/learning/addcourse.dart';
import 'package:freelance_system/learning/editcourse.dart';

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

      // Fetch enrolled courses (paid courses)
      var userCoursesSnapshot = await FirebaseFirestore.instance
          .collection('user_courses')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'paid')
          .get();

      List<String> enrolledCourseIds = userCoursesSnapshot.docs
          .map((doc) => doc['courseId'] as String)
          .toList();

      // Fetch courses added by the user (where userId matches current user)
      var userAddedCoursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('userId', isEqualTo: userId)
          .get();

      List<String> userAddedCourseIds =
          userAddedCoursesSnapshot.docs.map((doc) => doc.id).toList();

      // Combine both lists of course IDs
      List<String> allCourseIds = [...enrolledCourseIds, ...userAddedCourseIds];

      if (allCourseIds.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      var courseSnapshots = await FirebaseFirestore.instance
          .collection('courses')
          .where(FieldPath.documentId, whereIn: allCourseIds)
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
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1976D2),
              ),
            )
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
                      String? posterUrl = course['posterUrl'] as String?;
                      double price = course['price']?.toDouble() ?? 0.0;
                      final bool isAddedByUser = course['userId'] == userId;
                      final bool isPaid =
                          (course['paymentStatus'] ?? 'paid') == 'paid';
                      return GestureDetector(
                        onTap: () {
                          // Navigate to CourseDetail page when a course is clicked
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseDetail(
                                courseId: course['courseId'],
                                title: course['title'] ?? 'Course',
                                isAddedByUser: isAddedByUser,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              color: Colors.white,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    flex: 0,
                                    child: Container(
                                      height: 110,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        color: Colors.blue.shade50,
                                      ),
                                      child: posterUrl != null &&
                                              posterUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                              child: Image.network(
                                                posterUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 110,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(Icons.menu_book,
                                                        size: 54,
                                                        color: Colors
                                                            .blue.shade300),
                                              ),
                                            )
                                          : Center(
                                              child: Icon(Icons.menu_book,
                                                  size: 54,
                                                  color: Colors.blue.shade300),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course['title'] ?? 'No Title',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1976D2),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Instructor: ${course['username'] ?? 'Unknown'}",
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.currency_rupee,
                                                    size: 18,
                                                    color:
                                                        Colors.grey.shade800),
                                                Text(
                                                  price == 0
                                                      ? "Free"
                                                      : price
                                                          .toStringAsFixed(2),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Flexible(
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (isAddedByUser) ...[
                                                      GestureDetector(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      Editcourse(
                                                                courseId: course[
                                                                    'courseId'],
                                                                title: course[
                                                                        'title'] ??
                                                                    '',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Icon(
                                                          Icons.edit,
                                                          size: 26,
                                                          color:
                                                              Colors.blueGrey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      const Text(
                                                        'Your Course',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.blueGrey,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ] else if (isPaid) ...[
                                                      Icon(
                                                        Icons.check_circle,
                                                        size: 28,
                                                        color: Colors
                                                            .teal.shade600,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      const Text(
                                                        'Paid',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.teal,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ] else ...[
                                                      Icon(
                                                        Icons.school,
                                                        size: 26,
                                                        color: Colors.orange,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      const Text(
                                                        'Enrolled',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.orange,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAddedByUser)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Course'),
                                        content: const Text(
                                            'Are you sure you want to delete this course?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('courses')
                                          .doc(course['courseId'])
                                          .delete();
                                      setState(() {
                                        myCourses.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Course deleted successfully!')),
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Addcourse()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Course"),
      ),
    );
  }
}
