import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/chapterwidgets.dart';
import 'package:intl/intl.dart';

class CourseDetail extends StatefulWidget {
  final String courseId;
  final String title;

  const CourseDetail({super.key, required this.courseId, required this.title});

  @override
  State<CourseDetail> createState() => _CourseDetailState();
}

class _CourseDetailState extends State<CourseDetail> {
  Map<String, dynamic>? courseData;
  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;
  bool isPaid = false;
  String? userId; // To store the user ID

  @override
  void initState() {
    super.initState();
    fetchChapters();
    checkPaymentStatus();
  }

  Future<void> fetchChapters() async {
    try {
      var chapterSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('chapters')
          .get();

      List<Map<String, dynamic>> fetchedChapters =
          chapterSnapshot.docs.map((doc) {
        var data = doc.data();

        // Extract the chapter number from the chapter ID, e.g., "Chapter 1" -> 1
        String chapterId =
            doc.id.trim(); // Remove any extra spaces from the doc ID
        print("Chapter ID: $chapterId"); // Debugging: log the chapter ID

        RegExp regExp = RegExp(r'(\d+)'); // Match the numeric part
        var match = regExp.firstMatch(chapterId);

        if (match != null) {
          data['chapterNumber'] = int.tryParse(match.group(0) ?? '9999');
        } else {
          // If no match is found, log and set to 9999 (fallback)
          print("No match found for chapter ID: $chapterId");
          data['chapterNumber'] = 9999;
        }

        return data;
      }).toList();

      // Sort chapters by chapterNumber
      fetchedChapters
          .sort((a, b) => a['chapterNumber'].compareTo(b['chapterNumber']));

      setState(() {
        chapters = fetchedChapters;
      });
    } catch (e) {
      print("Error fetching chapters: $e");
    }
  }

  // Check if the user has paid for the course
  Future<void> checkPaymentStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid; // Store the userId

        // Query the user_courses collection to check if the payment has been made
        var userCourseSnapshot = await FirebaseFirestore.instance
            .collection('user_courses')
            .where('courseId', isEqualTo: widget.courseId)
            .where('userId', isEqualTo: userId)
            .get();

        if (userCourseSnapshot.docs.isNotEmpty) {
          var paymentStatus = userCourseSnapshot.docs.first['paymentStatus'];
          setState(() {
            isPaid = paymentStatus == 'paid';
          });
        } else {
          // If no payment record is found, set isPaid to false
          setState(() {
            isPaid = false;
          });
        }
      } else {
        print("User is not authenticated");
      }
    } catch (e) {
      print("Error checking payment status: $e");
    }
  }

  // Handle payment process
  Future<void> onPayNowPressed() async {
    // Simulate a payment process (You can integrate an actual payment gateway here)
    setState(() {
      isPaid = true; // Set the payment status to paid
    });

    // Store the payment status in the user_courses collection
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid; // Get the current user's ID

        // Check if the user already has an existing record
        var userCourseSnapshot = await FirebaseFirestore.instance
            .collection('user_courses')
            .where('courseId', isEqualTo: widget.courseId)
            .where('userId', isEqualTo: userId)
            .get();

        if (userCourseSnapshot.docs.isEmpty) {
          // If there's no record, add a new one
          await FirebaseFirestore.instance.collection('user_courses').add({
            'courseId': widget.courseId,
            'userId': userId, // Store the userId
            'paymentStatus': 'paid',
            'paymentDate': Timestamp.now(),
          });
          // After successfully adding payment, update the appliedUser count in the course
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.courseId)
              .update({
            'appliedUsers':
                FieldValue.increment(1), // Increment the appliedUser count by 1
          });
        } else {
          // If there's an existing record, update the payment status
          await FirebaseFirestore.instance
              .collection('user_courses')
              .doc(userCourseSnapshot.docs.first.id)
              .update({
            'paymentStatus': 'paid',
            'paymentDate': Timestamp.now(),
          });
        }

        // Optionally, you can show a confirmation message or proceed to next screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
      } else {
        print("User is not authenticated");
      }
    } catch (e) {
      print("Error storing payment status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .snapshots(), // Listen for real-time updates in the course data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading course data'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Course not found'));
          }

          // Get course data from snapshot
          var courseData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseData['title'] ?? "No title available",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 25),
                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      courseData['description'] ?? "No description available",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      textAlign: TextAlign.justify,
                      softWrap: true,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Benefits
                if (courseData['benefits'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Benefits of this Course:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (courseData['benefits'] as List)
                            .map<Widget>((benefit) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("• ",
                                          style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          benefit,
                                          style: const TextStyle(fontSize: 16),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),

                // Skills covered
                if (courseData['skills'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Skills Covered:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (courseData['skills'] as List)
                            .map<Widget>((skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),

                // Price and Pay Now Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      " Rs. ${courseData['price'] ?? "Not available"}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isPaid ? null : onPayNowPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isPaid ? "Paid" : "Pay Now",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Instructor
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Instructor: ${courseData['username'] ?? "Unknown"}",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Enrolled Users
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Enrolled Users: ${courseData['appliedUsers'] ?? 0}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Icon(
                      Icons.person_2,
                      size: 24,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Posted At
                Text(
                  "Posted At: ${DateFormat('yyyy-MM-dd').format((courseData['createdAt'] as Timestamp).toDate())}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Chapters Widget
                ChaptersWidget(
                    courseId: widget.courseId,
                    chapters: chapters,
                    isPaid: isPaid),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
