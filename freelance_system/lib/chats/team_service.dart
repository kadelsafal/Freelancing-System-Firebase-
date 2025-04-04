// team_service.dart (fixed to handle user details correctly)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/chats/user_service.dart';

class TeamService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final User? _user = FirebaseAuth.instance.currentUser;

  static Future<List<Map<String, dynamic>>> fetchUserTeams() async {
    if (_user == null) return [];

    QuerySnapshot snapshot = await _db
        .collection("teams")
        .where("members", arrayContains: _user!.uid)
        .get();

    List<Map<String, dynamic>> teams = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> teamData = doc.data() as Map<String, dynamic>;
      teamData['id'] = doc.id;

      // Get the latest message info
      QuerySnapshot messages = await _db
          .collection("teams")
          .doc(doc.id)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (messages.docs.isNotEmpty) {
        Map<String, dynamic> latestMessage =
            messages.docs.first.data() as Map<String, dynamic>;
        teamData['lastMessage'] = latestMessage['text'] ?? "";
        teamData['lastMessageTime'] = latestMessage['timestamp'];
      }

      teams.add(teamData);
    }

    return teams;
  }

  static Future<void> createTeam(
      {required String teamName,
      required String adminId,
      required List<String> memberIds}) async {
    if (_user == null) return;

    List<String> allMembers = [...memberIds];
    if (!allMembers.contains(adminId)) {
      allMembers.add(adminId);
    }

    if (!allMembers.contains(_user!.uid)) {
      allMembers.add(_user!.uid);
    }

    await _db.collection("teams").add({
      "teamName": teamName,
      "admin": adminId,
      "members": allMembers,
      "created_at": FieldValue.serverTimestamp(),
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendMessage(
    String teamId,
    String messageText, {
    required String? senderId,
    required String? senderName,
  }) async {
    if (senderId == null || senderName == null) return;

    final messageData = {
      'text': messageText,
      'sender': senderId,
      'senderName': senderName,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .add(messageData);

    // Update last message in team document
    await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
      'lastMessage': messageText,
      'lastMessageTime': Timestamp.now(),
    });
  }

  static Stream<QuerySnapshot> getTeamMessages(String teamId) {
    return _db
        .collection("teams")
        .doc(teamId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  static Future<Map<String, dynamic>> getTeamDetails(String teamId) async {
    DocumentSnapshot doc = await _db.collection("teams").doc(teamId).get();
    Map<String, dynamic> teamData = doc.data() as Map<String, dynamic>;
    teamData['id'] = doc.id;

    // Get member details
    List<Map<String, dynamic>> memberDetails = [];
    List<String> memberIds = List<String>.from(teamData['members'] ?? []);

    for (String memberId in memberIds) {
      // Fetch mutual followers (now the return type is List<Map<String, dynamic>>)
      List<Map<String, dynamic>> userDetails =
          await UserService.fetchMutualFollowers(memberId);

      // Add the fetched details for each member
      if (userDetails.isNotEmpty) {
        memberDetails.addAll(userDetails);
      }
    }

    teamData['memberDetails'] = memberDetails;
    return teamData;
  }
}
