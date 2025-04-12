import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> createIssue(String author, String projectId, String role,
    String issueText, List<String?> imageUrls) async {
  await FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .collection('issues')
      .add({
    'author': author,
    'issueText': issueText,
    'status': 'Not Solved',
    'role': role,
    'timestamp': Timestamp.now(),
    'imageUrls': imageUrls,
  });
}

Future<List<String?>> uploadImagesToCloudinary(List<XFile> files) async {
  const cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/dnebaumu9/image/upload";
  const preset = "Post Images";
  const folder = "public_posts";

  List<String?> urls = [];

  for (var file in files) {
    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var body = await response.stream.bytesToString();
      urls.add(jsonDecode(body)['secure_url']);
    } else {
      urls.add(null);
    }
  }

  return urls;
}
