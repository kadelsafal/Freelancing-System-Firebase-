import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class StatusService {
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    const url = "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
    const preset = "Post Images";
    const folder = "public_posts";
    List<String> urls = [];

    for (var image in imageFiles) {
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['upload_preset'] = preset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var json = jsonDecode(responseBody);
        urls.add(json['secure_url']);
      }
    }
    return urls;
  }

  static Future<void> markAsSeen(String projectId, String statusId, List seenBy,
      String currentUser) async {
    if (!seenBy.contains(currentUser)) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('statusUpdates')
          .doc(statusId)
          .update({
        'isSeenBy': FieldValue.arrayUnion([currentUser])
      });
    }
  }

  static Future<void> deleteStatus(String projectId, String statusId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('statusUpdates')
        .doc(statusId)
        .delete();
  }

  static Future<void> postStatusUpdate({
    required String projectId,
    required String author,
    required String role,
    required String text,
    required List<XFile> selectedImages,
  }) async {
    final urls = await uploadImages(selectedImages);
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('statusUpdates')
        .add({
      'author': author,
      'text': text,
      'images': urls,
      'role': role,
      'timestamp': Timestamp.now(),
      'isSeenBy': [author],
    });
  }
}
