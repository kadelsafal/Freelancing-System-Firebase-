// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// class PaymentSystem extends StatefulWidget {
//   const PaymentSystem({super.key});

//   @override
//   State<PaymentSystem> createState() => _PaymentSystemState();
// }

// class _PaymentSystemState extends State<PaymentSystem> {
//   File? uploadedReceipt;
//   bool isUploading = false;

//   Future<void> pickReceipt() async {
//     setState(() => isUploading = true);

//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
//     if (result != null) {
//       setState(() {
//         uploadedReceipt = File(result.files.single.path!);
//         isUploading = false;
//       });
//     } else {
//       setState(() => isUploading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F6FA),
//       appBar: AppBar(
//         title: const Text('Payments'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.deepPurple.shade50,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.deepPurple.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   )
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Freelancer Payment Summary",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       )),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Text("Total Earnings:", style: TextStyle(fontSize: 16)),
//                       Text("₹ 25,000",
//                           style: TextStyle(fontWeight: FontWeight.w600)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Text("Pending Payments:", style: TextStyle(fontSize: 16)),
//                       Text("₹ 5,000", style: TextStyle(color: Colors.orange)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Text("Last Paid:", style: TextStyle(fontSize: 16)),
//                       Text("March 28, 2025",
//                           style: TextStyle(color: Colors.green)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.08),
//                     blurRadius: 6,
//                     offset: const Offset(0, 3),
//                   )
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Upload Payment Receipt",
//                       style:
//                           TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 12),
//                   ElevatedButton.icon(
//                     onPressed: isUploading ? null : pickReceipt,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.deepPurple,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 14),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                     icon: const Icon(
//                       Icons.upload_file,
//                       color: Colors.white,
//                     ),
//                     label: Text(
//                       isUploading ? "Uploading..." : "Choose File",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   if (uploadedReceipt != null) ...[
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         const Icon(Icons.insert_drive_file,
//                             color: Colors.deepPurple),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             uploadedReceipt!.path.split('/').last,
//                             style: const TextStyle(fontSize: 14),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ]
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: uploadedReceipt == null
//                   ? null
//                   : () {
//                       // Simulate payment confirmation or Firestore write
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                           content:
//                               Text('Payment receipt uploaded successfully!')));
//                     },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child:
//                   const Text("Confirm Payment", style: TextStyle(fontSize: 16)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
