import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/learning/chapterwidgets.dart';
import 'package:intl/intl.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';

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
  bool isPaid = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchChapters();
    checkPaymentStatus();
  }

  Future<void> fetchChapters() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('chapters')
          .get();

      List<Map<String, dynamic>> fetchedChapters = snapshot.docs.map((doc) {
        var data = doc.data();
        var chapterId = doc.id.trim();

        // Extract chapter number using RegExp
        final match = RegExp(r'(\d+)').firstMatch(chapterId);
        data['chapterNumber'] = match != null
            ? int.tryParse(match.group(0) ?? '9999') ?? 9999
            : 9999;

        return data;
      }).toList();

      // Sort by chapter number
      fetchedChapters
          .sort((a, b) => a['chapterNumber'].compareTo(b['chapterNumber']));

      setState(() {
        chapters = fetchedChapters;
      });
    } catch (e) {
      print("Error fetching chapters: $e");
    }
  }

  Future<void> checkPaymentStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not authenticated");
        return;
      }

      userId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('user_courses')
          .where('courseId', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final status = snapshot.docs.first['paymentStatus'];
        setState(() {
          isPaid = status == 'paid';
        });
      }
    } catch (e) {
      print("Error checking payment status: $e");
    }
  }

  // Future<void> onPayNowPressed() async {
  //   final price = double.tryParse('${courseData?['price'] ?? 0}') ?? 0.0;

  //   if (price <= 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Invalid course price')),
  //     );
  //     return;
  //   }

  //   KhaltiScope.of(context).pay(
  //     config: PaymentConfig(
  //       amount: (price * 100).toInt(), // Khalti uses paisa
  //       productIdentity: widget.courseId,
  //       productName: widget.title,
  //     ),
  //     preferences: [PaymentPreference.khalti],
  //     onSuccess: (success) async {
  //       try {
  //         final user = FirebaseAuth.instance.currentUser;
  //         if (user == null) return;

  //         final uid = user.uid;
  //         final ref = FirebaseFirestore.instance.collection('user_courses');

  //         final existing = await ref
  //             .where('courseId', isEqualTo: widget.courseId)
  //             .where('userId', isEqualTo: uid)
  //             .get();

  //         if (existing.docs.isEmpty) {
  //           await ref.add({
  //             'courseId': widget.courseId,
  //             'userId': uid,
  //             'paymentStatus': 'paid',
  //             'paymentDate': Timestamp.now(),
  //           });

  //           await FirebaseFirestore.instance
  //               .collection('courses')
  //               .doc(widget.courseId)
  //               .update({'appliedUsers': FieldValue.increment(1)});
  //         } else {
  //           await ref.doc(existing.docs.first.id).update({
  //             'paymentStatus': 'paid',
  //             'paymentDate': Timestamp.now(),
  //           });
  //         }

  //         setState(() {
  //           isPaid = true;
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Payment successful!')),
  //         );
  //       } catch (e, stackTrace) {
  //         print("Firestore error after payment: $e\n$stackTrace");
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //               content: Text('Payment succeeded but something went wrong.')),
  //         );
  //       }
  //     },
  //     onFailure: (failure) {
  //       print("Khalti Payment Failed: ${failure.message}");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Payment failed: ${failure.message}')),
  //       );
  //     },
  //     onCancel: () {
  //       print("Khalti payment cancelled by user.");
  //     },
  //   );
  // }

  Future<void> onPayNowPressed() async {
    final price = double.tryParse('${courseData?['price'] ?? 0}') ?? 0.0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid course price')),
      );
      return;
    }

    verify(EsewaPaymentSuccessResult result) {
      // This is called when the payment is successful
    }

    try {
      EsewaFlutterSdk.initPayment(
          esewaConfig: EsewaConfig(
            environment: Environment.test, // Change to .live for production
            clientId: 'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R',
            secretId: 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==',
          ),
          esewaPayment: EsewaPayment(
              productId: widget.courseId,
              productName: widget.title,
              productPrice: price.toStringAsFixed(2),
              callbackUrl: ''),
          onPaymentSuccess: (EsewaPaymentSuccessResult result) async {
            debugPrint("Success");
            verify(result);

            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) return;

            final ref = FirebaseFirestore.instance.collection('user_courses');

            final existing = await ref
                .where('courseId', isEqualTo: widget.courseId)
                .where('userId', isEqualTo: uid)
                .get();

            final transactionId = result.refId ?? 'N/A';
            final paidAmount = price ?? 'N/A';

            // Prepare full payment result as a map
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
                'courseId': widget.courseId,
                'userId': uid,
                'paymentStatus': 'paid',
                'paymentDate': Timestamp.now(),
                'transactionId': transactionId,
                'paidAmount': paidAmount,
                'paymentResult': paymentData, // storing full eSewa result
              });

              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .update({'appliedUsers': FieldValue.increment(1)});
            } else {
              await ref.doc(existing.docs.first.id).update({
                'paymentStatus': 'paid',
                'paymentDate': Timestamp.now(),
                'transactionId': transactionId,
                'paidAmount': paidAmount,
                'paymentResult': paymentData, // storing full eSewa result
              });
            }

            setState(() {
              isPaid = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful via eSewa!')),
            );

            showInvoiceDialog(context, result); // Optional invoice popup
          },
          onPaymentFailure: () {
            debugPrint("Failure");
          },
          onPaymentCancellation: () {
            debugPrint("Cancellation");
          });
    } catch (e) {
      print("Esewa Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during payment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
                child: Text('Course not found or failed to load.'));
          }

          courseData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  courseData?['title'] ?? "No title available",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),

                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    courseData?['description'] ?? "No description available",
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 30),

                // Benefits
                if (courseData?['benefits'] is List)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Benefits of this Course:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...List<Widget>.from(
                        (courseData!['benefits'] as List).map((benefit) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• ",
                                      style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                      child: Text(benefit,
                                          style:
                                              const TextStyle(fontSize: 16))),
                                ],
                              ),
                            )),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),

                // Skills
                if (courseData?['skills'] is List)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Skills Covered:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.from(
                          (courseData!['skills'] as List)
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(skill,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14)),
                                  )),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),

                // Price and Payment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rs. ${courseData?['price'] ?? "N/A"}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: isPaid ? null : onPayNowPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isPaid ? "Paid" : "Pay Now",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Instructor
                Text(
                  "Instructor: ${courseData?['username'] ?? "Unknown"}",
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),

                const SizedBox(height: 10),

                // Enrolled users
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Enrolled Users: ${courseData?['appliedUsers'] ?? 0}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Icon(Icons.person_2, color: Colors.deepPurple),
                  ],
                ),

                const SizedBox(height: 10),

                // Created At
                Text(
                  "Posted At: ${_formatDate(courseData?['createdAt'])}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // Chapters widget
                ChaptersWidget(
                  courseId: widget.courseId,
                  chapters: chapters,
                  isPaid: isPaid,
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      return DateFormat('yyyy-MM-dd').format((timestamp as Timestamp).toDate());
    } catch (_) {
      return "Unknown";
    }
  }

  void showInvoiceDialog(
      BuildContext context, EsewaPaymentSuccessResult result) {
    final now = DateTime.now();
    final formattedDate = DateFormat.yMMMMd().add_jm().format(now);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🧾 Course: ${widget.title}"),
            Text("📚 Course ID: ${widget.courseId}"),
            Text("💳 Paid: Rs. ${courseData?['price'] ?? '0'}"),
            Text("🔐 Transaction ID: ${result.refId ?? 'N/A'}"),
            Text("⏰ Date: $formattedDate"),
            const SizedBox(height: 12),
            const Text("✅ Payment Method: eSewa"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }
}
