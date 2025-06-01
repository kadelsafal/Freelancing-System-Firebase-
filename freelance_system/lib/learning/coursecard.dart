import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/courseDetail.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _onBuyNowPressed(BuildContext context, double price) async {
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid course price')),
      );
      return;
    }

    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test, // Change to .live for production
          clientId: 'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R',
          secretId: 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==',
        ),
        esewaPayment: EsewaPayment(
          productId: CourseId,
          productName: title,
          productPrice: price.toStringAsFixed(2),
          callbackUrl: '',
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult result) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;

          final ref = FirebaseFirestore.instance.collection('user_courses');
          final existing = await ref
              .where('courseId', isEqualTo: CourseId)
              .where('userId', isEqualTo: uid)
              .get();

          final transactionId = result.refId ?? 'N/A';
          final paidAmount = price;

          final paymentData = {
            'productId': result.productId,
            'productName': result.productName,
            'totalAmount': result.totalAmount,
            'referenceId': result.refId,
            'status': result.status,
            'merchantName': result.merchantName,
            'message': result.message,
            'timestamp': Timestamp.now(),
          };

          if (existing.docs.isEmpty) {
            await ref.add({
              'courseId': CourseId,
              'userId': uid,
              'paymentStatus': 'paid',
              'paymentDate': Timestamp.now(),
              'transactionId': transactionId,
              'paidAmount': paidAmount,
              'paymentResult': paymentData,
            });

            await FirebaseFirestore.instance
                .collection('courses')
                .doc(CourseId)
                .update({'appliedUsers': FieldValue.increment(1)});
          } else {
            await ref.doc(existing.docs.first.id).update({
              'paymentStatus': 'paid',
              'paymentDate': Timestamp.now(),
              'transactionId': transactionId,
              'paidAmount': paidAmount,
              'paymentResult': paymentData,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful via eSewa!')),
          );
          // Pop back to the root (AllCourses) to prevent unwanted navigation
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onPaymentFailure: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed!')),
          );
        },
        onPaymentCancellation: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled!')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
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
        String? posterUrl = courseData['posterUrl'] as String?;

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
          child: SizedBox(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster or icon
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
                      child: posterUrl != null && posterUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 110,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.menu_book,
                                        size: 54, color: Colors.blue.shade300),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.menu_book,
                                  size: 54, color: Colors.blue.shade300),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13, // Decreased font size
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 18, color: Colors.blue.shade400),
                            const SizedBox(width: 4),
                            Text(
                              "Enrolled: $appliedUser",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.currency_rupee,
                                    size: 18, color: Colors.grey.shade800),
                                Text(
                                  price == 0
                                      ? "Free"
                                      : price.toStringAsFixed(2),
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
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () =>
                                        _onBuyNowPressed(context, price),
                                    child: const Text(
                                      "Buy Now",
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
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
          ),
        );
      },
    );
  }
}
