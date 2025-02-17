import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/courseDetail.dart';

class CourseCard extends StatelessWidget {
  final String CourseId;
  final String title;
  final String courseType;

  const CourseCard({
    super.key,
    required this.CourseId,
    required this.title,
    required this.courseType,
  });

  // Function to get the appropriate icon for the course type
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(CourseId)
          .snapshots(), // Listen to the changes for this specific course
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var courseData = snapshot.data?.data() as Map<String, dynamic>?;

        if (courseData == null) {
          return const Center(child: Text('Course not found'));
        }

        // Extract the course price and applied user count
        double price = courseData['price']?.toDouble() ?? 0.0;
        int appliedUser = courseData['appliedUsers'] ?? 0;

        return InkWell(
          onTap: () {
            // Navigate to Course Details Page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetail(
                  title: title,
                  courseId: CourseId,
                ),
              ),
            );
          },
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display the appropriate icon based on course type
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
                    child: Center(child: _getCourseTypeIcon(courseType)),
                  ),
                  SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Enrolled: $appliedUser",
                        style: TextStyle(fontSize: 12),
                      ),
                      Icon(
                        Icons.person_2,
                        size: 24,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor:
                                const Color.fromRGBO(255, 255, 255, 1),
                            padding: EdgeInsets.all(8),
                          ),
                          onPressed: () {
                            // Implement Payment Logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Payment feature coming soon!")),
                            );
                          },
                          child: const Text(
                            "Buy Now",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
