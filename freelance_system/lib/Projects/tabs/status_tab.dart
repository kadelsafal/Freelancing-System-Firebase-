import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class StatusTab extends StatefulWidget {
  final String projectId;
  final String role;

  const StatusTab({
    super.key,
    required this.projectId,
    required this.role,
  });

  @override
  _StatusTabState createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  final TextEditingController _statusUpdateController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final List<bool> _imageLoadingStatus = [];
  bool _isPostingUpdate = false;

  @override
  void initState() {
    super.initState();
  }

  Future<List<String?>> uploadImagesToCloudinary(List<XFile> imageFiles) async {
    const cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
    const uploadPreset = "Post Images";
    const folder = "public_posts";
    List<String?> uploadedUrls = [];

    try {
      for (var imageFile in imageFiles) {
        setState(() {
          _imageLoadingStatus.add(true);
        });

        var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
        request.fields['upload_preset'] = uploadPreset;
        request.fields['folder'] = folder;
        request.files
            .add(await http.MultipartFile.fromPath('file', imageFile.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseBody);
          uploadedUrls.add(jsonResponse['secure_url']);
        } else {
          uploadedUrls.add(null);
        }

        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _imageLoadingStatus.removeAt(_selectedImages.indexOf(imageFile));
        });
      }
      return uploadedUrls;
    } catch (e) {
      print("Error uploading images: $e");
      return [];
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles
            .where((file) => !_selectedImages.contains(file))
            .toList());
      });
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageLoadingStatus.removeAt(index);
    });
  }

  void _addStatusUpdate(String author, String projectId) async {
    if (_statusUpdateController.text.isNotEmpty || _selectedImages.isNotEmpty) {
      setState(() {
        _isPostingUpdate = true;
      });

      List<String?> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await uploadImagesToCloudinary(_selectedImages);
      }

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('statusUpdates')
          .add({
        'author': author,
        'text': _statusUpdateController.text,
        'images': imageUrls.where((url) => url != null).toList(),
        'role': widget.role,
        'timestamp': Timestamp.now(),
        'isSeenBy': [author], // Mark as seen by author immediately
      });

      setState(() {
        _selectedImages.clear();
        _imageLoadingStatus.clear();
        _statusUpdateController.clear();
        _isPostingUpdate = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status update posted successfully!")));
    }
  }

  // Modify _markAsSeen to handle unseen updates properly
  Future<void> _markAsSeen(
      String docId, List seenBy, String currentUser) async {
    if (!seenBy.contains(currentUser)) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('statusUpdates')
          .doc(docId)
          .update({
        'isSeenBy': FieldValue.arrayUnion(
            [currentUser]), // Mark as seen by the current user
      });
    }
  }

  Future<void> _deleteStatus(String statusId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('statusUpdates')
        .doc(statusId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Project not found"));
        } else {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('projects')
                        .doc(widget.projectId)
                        .collection('statusUpdates')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, statusSnapshot) {
                      if (statusSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (statusSnapshot.hasError) {
                        return Center(
                            child: Text("Error: ${statusSnapshot.error}"));
                      } else if (!statusSnapshot.hasData ||
                          statusSnapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No status updates"));
                      } else {
                        final docs = statusSnapshot.data!.docs;

                        return ListView.builder(
                          reverse: true,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var doc = docs[index];
                            var statusData = doc.data() as Map<String, dynamic>;
                            List seenBy = statusData['isSeenBy'] ?? [];

                            bool isSender = currentName == statusData['author'];
                            bool isSeen = seenBy.contains(currentName);

                            // Mark as seen if it's not the sender and it's unseen
                            if (!isSender && !isSeen) {
                              _markAsSeen(doc.id, seenBy, currentName);
                            }

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () async {
                                  if (isSender) {
                                    bool? confirmDelete = await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Delete Status'),
                                          content: const Text(
                                              'Are you sure you want to delete this status update?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirmDelete == true) {
                                      _deleteStatus(doc.id);
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: isSender
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSender
                                            ? Colors.blue.shade100
                                            : isSeen
                                                ? const Color.fromARGB(
                                                    255, 156, 255, 162)
                                                : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                child: Text(
                                                  statusData['author'][0],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                statusData['author'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              if (!isSeen && !isSender)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 8.0),
                                                  child: Text(
                                                    "🟢 Unseen",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            statusData['text'],
                                            style: TextStyle(
                                              fontWeight: !isSeen && !isSender
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (statusData['images'] != null &&
                                              statusData['images'].isNotEmpty)
                                            Column(
                                              children: [
                                                SizedBox(
                                                  height: 100,
                                                  child: Wrap(
                                                    direction: Axis.horizontal,
                                                    children: List.generate(
                                                      statusData['images']
                                                          .length,
                                                      (index) {
                                                        String imageUrl =
                                                            statusData['images']
                                                                [index];
                                                        return GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => Dialog(
                                                                  child: Image
                                                                      .network(
                                                                          imageUrl)),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child:
                                                                Image.network(
                                                              imageUrl,
                                                              height: 100,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                            ),
                                          Text(
                                            "${(statusData['timestamp'] as Timestamp).toDate()}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    maxLines: null,
                    controller: _statusUpdateController,
                    decoration: InputDecoration(
                      labelText: "Post a Status Update",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _selectedImages.isEmpty
                              ? Icons.image
                              : Icons.add_a_photo,
                        ),
                        onPressed: _selectImage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_selectedImages.isNotEmpty)
                  Wrap(
                    children: List.generate(_selectedImages.length, (index) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.file(
                            File(_selectedImages[index].path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () => _deleteImage(index),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isPostingUpdate
                      ? null
                      : () => _addStatusUpdate(currentName, widget.projectId),
                  child: _isPostingUpdate
                      ? const CircularProgressIndicator()
                      : const Text("Post Update"),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
