// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:freelance_system/profile_controller/imageslider.dart';
// import 'package:freelance_system/providers/userProvider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// class StatusTab extends StatefulWidget {
//   final String projectId;
//   final String role;

//   const StatusTab({
//     super.key,
//     required this.projectId,
//     required this.role,
//   });

//   @override
//   _StatusTabState createState() => _StatusTabState();
// }

// class _StatusTabState extends State<StatusTab> {
//   final TextEditingController _statusUpdateController = TextEditingController();
//   final List<XFile> _selectedImages = [];
//   final Map<String, PageController> _pageControllers = {};
//   final Map<String, int> _currentPageIndex = {};

//   bool _isPostingUpdate = false;

//   Future<List<String>> uploadImagesToCloudinary(List<XFile> imageFiles) async {
//     const cloudinaryUrl =
//         "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
//     const uploadPreset = "Post Images";
//     const folder = "public_posts";

//     List<String> uploadedUrls = [];

//     for (var imageFile in imageFiles) {
//       var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..fields['folder'] = folder
//         ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseBody = await response.stream.bytesToString();
//         var jsonResponse = jsonDecode(responseBody);
//         uploadedUrls.add(jsonResponse['secure_url']);
//       }
//     }

//     return uploadedUrls;
//   }

//   Future<void> _showImagePickerOptions() async {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (BuildContext context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Pick from Gallery'),
//                 onTap: () async {
//                   Navigator.of(context).pop();
//                   final picker = ImagePicker();
//                   final pickedFiles = await picker.pickMultiImage();
//                   if (pickedFiles != null) {
//                     setState(() {
//                       _selectedImages.addAll(pickedFiles);
//                     });
//                   }
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Take a Photo'),
//                 onTap: () async {
//                   Navigator.of(context).pop();
//                   final picker = ImagePicker();
//                   final photo =
//                       await picker.pickImage(source: ImageSource.camera);
//                   if (photo != null) {
//                     setState(() {
//                       _selectedImages.add(photo);
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _deleteImage(int index) {
//     setState(() {
//       _selectedImages.removeAt(index);
//     });
//   }

//   Future<void> _addStatusUpdate(String author, String projectId) async {
//     if (_statusUpdateController.text.isEmpty && _selectedImages.isEmpty) return;

//     setState(() {
//       _isPostingUpdate = true;
//     });

//     List<String> imageUrls = await uploadImagesToCloudinary(_selectedImages);

//     await FirebaseFirestore.instance
//         .collection('projects')
//         .doc(projectId)
//         .collection('statusUpdates')
//         .add({
//       'author': author,
//       'text': _statusUpdateController.text,
//       'images': imageUrls,
//       'role': widget.role,
//       'timestamp': Timestamp.now(),
//       'isSeenBy': [author],
//     });

//     setState(() {
//       _selectedImages.clear();
//       _statusUpdateController.clear();
//       _isPostingUpdate = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Status update posted successfully!")));
//   }

//   Future<void> _markAsSeen(
//       String docId, List seenBy, String currentUser) async {
//     if (!seenBy.contains(currentUser)) {
//       await FirebaseFirestore.instance
//           .collection('projects')
//           .doc(widget.projectId)
//           .collection('statusUpdates')
//           .doc(docId)
//           .update({
//         'isSeenBy': FieldValue.arrayUnion([currentUser])
//       });
//     }
//   }

//   Future<void> _deleteStatus(String statusId) async {
//     await FirebaseFirestore.instance
//         .collection('projects')
//         .doc(widget.projectId)
//         .collection('statusUpdates')
//         .doc(statusId)
//         .delete();
//   }

//   @override
//   void dispose() {
//     _statusUpdateController.dispose();
//     // Dispose controllers when widget is disposed
//     for (var controller in _pageControllers.values) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var userProvider = Provider.of<Userprovider>(context);
//     String currentName = userProvider.userName;

//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('projects')
//           .doc(widget.projectId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snapshot.hasError) {
//           return Center(child: Text("Error: ${snapshot.error}"));
//         }
//         if (!snapshot.hasData || !snapshot.data!.exists) {
//           return const Center(child: Text("Project not found"));
//         }

//         return Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               Expanded(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('projects')
//                       .doc(widget.projectId)
//                       .collection('statusUpdates')
//                       .orderBy('timestamp', descending: true)
//                       .snapshots(),
//                   builder: (context, statusSnapshot) {
//                     if (statusSnapshot.connectionState ==
//                         ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (statusSnapshot.hasError) {
//                       return Center(
//                           child: Text("Error: ${statusSnapshot.error}"));
//                     }

//                     final docs = statusSnapshot.data?.docs ?? [];
//                     if (docs.isEmpty) {
//                       return const Center(child: Text("No status updates"));
//                     }

//                     return ListView.builder(
//                       reverse: true,
//                       itemCount: docs.length,
//                       itemBuilder: (context, index) {
//                         var doc = docs[index];
//                         var statusData = doc.data() as Map<String, dynamic>;
//                         List seenBy = statusData['isSeenBy'] ?? [];

//                         bool isSender = currentName == statusData['author'];
//                         bool isSeen = seenBy.contains(currentName);

//                         if (!isSender && !isSeen) {
//                           _markAsSeen(doc.id, seenBy, currentName);
//                         }

//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 4.0),
//                           child: GestureDetector(
//                             onDoubleTap: () async {
//                               if (isSender) {
//                                 bool? confirmDelete = await showDialog(
//                                   context: context,
//                                   builder: (context) => AlertDialog(
//                                     title: const Text('Delete Status'),
//                                     content: const Text(
//                                         'Are you sure you want to delete this status update?'),
//                                     actions: [
//                                       TextButton(
//                                           onPressed: () =>
//                                               Navigator.pop(context, false),
//                                           child: const Text('Cancel')),
//                                       TextButton(
//                                           onPressed: () =>
//                                               Navigator.pop(context, true),
//                                           child: const Text('Delete')),
//                                     ],
//                                   ),
//                                 );
//                                 if (confirmDelete == true) {
//                                   _deleteStatus(doc.id);
//                                 }
//                               }
//                             },
//                             child: Align(
//                               alignment: isSender
//                                   ? Alignment.centerRight
//                                   : Alignment.centerLeft,
//                               child: Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: isSender
//                                       ? Colors.blue.shade100
//                                       : isSeen
//                                           ? Colors.green.shade100
//                                           : Colors.orange.shade100,
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 16,
//                                           child: Text(statusData['author'][0]),
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Text(statusData['author'],
//                                             style: const TextStyle(
//                                                 fontWeight: FontWeight.bold)),
//                                         if (!isSeen && !isSender)
//                                           const Padding(
//                                             padding: EdgeInsets.only(left: 8),
//                                             child: Text("🟢 Unseen",
//                                                 style: TextStyle(
//                                                     fontWeight:
//                                                         FontWeight.bold)),
//                                           ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                     if ((statusData['text'] as String)
//                                         .isNotEmpty)
//                                       Text(statusData['text']),
//                                     const SizedBox(height: 15),
//                                     if (statusData['images'] != null &&
//                                         statusData['images'].isNotEmpty)
//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width *
//                                                 0.5,
//                                         child: Imageslider(
//                                           heightFactor: 0.2,
//                                           imageWidth: 200,
//                                           imageUrls: List<String>.from(
//                                               statusData['images']),
//                                         ),
//                                       ),
//                                     Wrap(
//                                       spacing: 4,
//                                       children: seenBy.isNotEmpty
//                                           ? seenBy
//                                               .where((name) =>
//                                                   name !=
//                                                   statusData[
//                                                       'author']) // Exclude sender from seen avatars
//                                               .map((name) => CircleAvatar(
//                                                     radius: 8,
//                                                     child: Text(
//                                                       name[
//                                                           0], // First letter of the name
//                                                       style: TextStyle(
//                                                           fontSize: 10),
//                                                     ),
//                                                   ))
//                                               .toList()
//                                           : [],
//                                     )
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               if (widget.role != 'client')
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Column(
//                     children: [
//                       if (_selectedImages.isNotEmpty)
//                         SizedBox(
//                           height: 100,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: _selectedImages.length,
//                             itemBuilder: (context, index) {
//                               return Padding(
//                                 padding:
//                                     const EdgeInsets.symmetric(horizontal: 8),
//                                 child: Stack(
//                                   children: [
//                                     Image.file(
//                                       File(_selectedImages[index].path),
//                                       width: 80,
//                                       height: 80,
//                                       fit: BoxFit.cover,
//                                     ),
//                                     Positioned(
//                                       top: 0,
//                                       right: 0,
//                                       child: IconButton(
//                                         icon: const Icon(Icons.remove_circle),
//                                         onPressed: () => _deleteImage(index),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               const SizedBox(height: 25),
//               TextField(
//                 maxLines: null,
//                 controller: _statusUpdateController,
//                 decoration: InputDecoration(
//                   labelText: "Post a Status Update",
//                   border: const OutlineInputBorder(),
//                   suffixIcon: IconButton(
//                     icon: Icon(_selectedImages.isEmpty
//                         ? Icons.image
//                         : Icons.add_a_photo),
//                     onPressed: _showImagePickerOptions,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               if (_selectedImages.isNotEmpty)
//                 Wrap(
//                   spacing: 8,
//                   children: List.generate(_selectedImages.length, (index) {
//                     return Stack(
//                       children: [
//                         Image.file(
//                           File(_selectedImages[index].path),
//                           width: 80,
//                           height: 80,
//                           fit: BoxFit.cover,
//                         ),
//                         Positioned(
//                           top: -4,
//                           right: -4,
//                           child: IconButton(
//                             icon: const Icon(Icons.remove_circle,
//                                 color: Colors.red),
//                             onPressed: () => _deleteImage(index),
//                           ),
//                         ),
//                       ],
//                     );
//                   }),
//                 ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _isPostingUpdate
//                     ? null
//                     : () => _addStatusUpdate(currentName, widget.projectId),
//                 child: _isPostingUpdate
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text("Post Update"),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
