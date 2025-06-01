import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // user_service.dart
  // Fetch both full name and profile image
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();

    return {
      'name':
          data?['Full Name'] ?? data?['fullName'] ?? data?['displayName'] ?? '',
      'profileImage': data?['profile_image'],
    };
  }

  static Future<List<Map<String, dynamic>>> fetchMutualFollowers(
      String userId) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Get the user's followers
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      // Fetch followers list
      QuerySnapshot followersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();
      List<String> followers =
          followersSnapshot.docs.map((doc) => doc.id).toList();

      // Fetch following list
      QuerySnapshot followingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();
      List<String> following =
          followingSnapshot.docs.map((doc) => doc.id).toList();

      // Find mutual followers
      List<String> mutualIds =
          followers.where((id) => following.contains(id)).toList();

      // Fetch user details for mutual followers
      List<Map<String, dynamic>> mutualUsers = [];

      for (String mutualId in mutualIds) {
        DocumentSnapshot mutualUserDoc =
            await _firestore.collection('users').doc(mutualId).get();

        if (mutualUserDoc.exists) {
          mutualUsers.add({
            "id": mutualId,
            "fullName": mutualUserDoc["Full Name"] ?? "Unknown User",
            "email": mutualUserDoc["email"] ?? "",
            "profileImage": mutualUserDoc["profile_image"],
          });
        }
      }

      return mutualUsers;
    } catch (e) {
      print("Error fetching mutual followers: $e");
      return [];
    }
  }
}
