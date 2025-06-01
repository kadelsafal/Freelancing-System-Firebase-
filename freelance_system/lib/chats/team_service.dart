// team_service.dart (fixed to handle user details correctly)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/chats/user_service.dart';
import 'package:rxdart/rxdart.dart'; // Add rxdart to pubspec.yaml
import 'package:flutter/material.dart';

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

    Set<String> allMembers = {...memberIds, adminId, _user!.uid};

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
      'isSeenBy': [],
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

  static Future<void> markMessagesAsSeen(
      QuerySnapshot snapshot, String currentUserId) async {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final seenList = List<String>.from(data['isSeenBy'] ?? []);
      final senderId = data['sender'] != null
          ? data['sender'] as String
          : throw Exception('Sender ID is missing');

      // Check if the current user has not seen the message yet
      if (!seenList.contains(currentUserId) && senderId != currentUserId) {
        await doc.reference.update({
          'isSeenBy': FieldValue.arrayUnion(
              [currentUserId]), // Mark the message as seen by the current user
        });
      }
    }
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

  // static Future<String> getUserNameById(String userId) async {
  //   try {
  //     // Access Firestore to get the user data
  //     DocumentSnapshot userDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(userId)
  //         .get();

  //     // Check if the document exists
  //     if (userDoc.exists) {
  //       // Retrieve the name from the user document
  //       var name = userDoc['Full Name'];
  //       var profile = userDoc['profile_image'];
  //       // If name exists, return it, otherwise return a fallback string
  //       return name ?? 'U'; // 'U' for unknown if no name exists
  //     } else {
  //       // Handle case where document does not exist
  //       return 'U';
  //     }
  //   } catch (e) {
  //     print('Error fetching user name: $e');
  //     return 'U'; // Return 'U' in case of error
  //   }
  // }

  static Future<Map<String, String>> getUserInfoById(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final name = userDoc['Full Name'] ?? 'U';
        final profileImage = userDoc['profile_image'] ?? '';
        return {
          'name': name,
          'profileImage': profileImage,
        };
      } else {
        return {
          'name': 'U',
          'profileImage': '',
        };
      }
    } catch (e) {
      print('Error fetching user info: $e');
      return {
        'name': 'U',
        'profileImage': '',
      };
    }
  }

  static Stream<int> getUnseenMessagesCountStream(String currentUserId) {
    final userTeamsStream = FirebaseFirestore.instance
        .collection('teams')
        .where('members', arrayContains: currentUserId)
        .snapshots();

    return userTeamsStream.switchMap((teamsSnapshot) {
      final teamIds = teamsSnapshot.docs.map((doc) => doc.id).toList();

      if (teamIds.isEmpty) return Stream.value(0);

      final List<Stream<int>> unseenStreams = teamIds.map((teamId) {
        return FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .collection('messages')
            .snapshots()
            .map((messagesSnapshot) {
          int count = 0;
          for (var doc in messagesSnapshot.docs) {
            final data = doc.data();
            final sender = data['sender'];
            final isSeenBy = List<String>.from(data['isSeenBy'] ?? []);
            if (sender != currentUserId && !isSeenBy.contains(currentUserId)) {
              count++;
            }
          }
          print("🔴 Unseen in team $teamId: $count");
          return count;
        });
      }).toList();

      return Rx.combineLatestList(unseenStreams).map((counts) {
        final total = counts.fold(0, (sum, val) => sum + val);
        print("🔴 Total unseen messages across all teams: $total");
        return total;
      });
    });
  }

  static Stream<bool> isLastMessageUnseen(String teamId, String currentUserId) {
    return FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return false;

      final message = snapshot.docs.first.data();
      final sender = message['sender'];
      final isSeenBy = List<String>.from(message['isSeenBy'] ?? []);

      return sender != currentUserId && !isSeenBy.contains(currentUserId);
    });
  }

  // Get the stream of user teams from Firestore
  static Stream<List<Map<String, dynamic>>> getUserTeamsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  // Fetch the unseen message count for a specific team and user

  // static Future<void> showCreateTeamDialog(BuildContext context) async {
  //   final TextEditingController teamNameController = TextEditingController();
  //   final TextEditingController descriptionController = TextEditingController();
  //   final currentUser = FirebaseAuth.instance.currentUser;

  //   if (currentUser == null) return;

  //   // Get current user's profile
  //   final userProfile = await UserService.getUserProfile(currentUser.uid);
  //   final userName = userProfile?['name'] ?? 'User';
  //   final userProfileImage = userProfile?['profileImage'] ?? '';
  //   final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

  //   return showDialog(
  //     context: context,
  //     builder: (context) => Dialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //       elevation: 0,
  //       backgroundColor: Colors.transparent,
  //       child: Container(
  //         padding: const EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(20),
  //           boxShadow: [
  //             BoxShadow(
  //               color: const Color(0xFF1976D2).withOpacity(0.1),
  //               blurRadius: 10,
  //               spreadRadius: 5,
  //             ),
  //           ],
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(15),
  //               decoration: BoxDecoration(
  //                 gradient: const LinearGradient(
  //                   colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                 ),
  //                 borderRadius: BorderRadius.circular(15),
  //               ),
  //               child: Row(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 25,
  //                     backgroundColor: Colors.white,
  //                     backgroundImage: userProfileImage.isNotEmpty
  //                         ? NetworkImage(userProfileImage)
  //                         : null,
  //                     child: userProfileImage.isEmpty
  //                         ? Text(
  //                             initial,
  //                             style: const TextStyle(
  //                               fontSize: 22,
  //                               color: Color(0xFF1976D2),
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           )
  //                         : null,
  //                   ),
  //                   const SizedBox(width: 15),
  //                   const Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           'Create New Team',
  //                           style: TextStyle(
  //                             fontSize: 22,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                         SizedBox(height: 4),
  //                         Text(
  //                           'Start collaborating with your team',
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Colors.white70,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             TextField(
  //               controller: teamNameController,
  //               decoration: InputDecoration(
  //                 labelText: 'Team Name',
  //                 hintText: 'Enter team name',
  //                 filled: true,
  //                 fillColor: const Color(0xFF1976D2).withOpacity(0.05),
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide: BorderSide.none,
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide:
  //                       const BorderSide(color: Color(0xFF1976D2), width: 2),
  //                 ),
  //                 prefixIcon: Container(
  //                   padding: const EdgeInsets.all(12),
  //                   child: const Icon(Icons.group, color: Color(0xFF1976D2)),
  //                 ),
  //                 contentPadding: const EdgeInsets.symmetric(vertical: 16),
  //                 labelStyle: const TextStyle(color: Color(0xFF1976D2)),
  //               ),
  //             ),
  //             const SizedBox(height: 15),
  //             TextField(
  //               controller: descriptionController,
  //               maxLines: 3,
  //               decoration: InputDecoration(
  //                 labelText: 'Description',
  //                 hintText: 'Enter team description',
  //                 filled: true,
  //                 fillColor: const Color(0xFF1976D2).withOpacity(0.05),
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide: BorderSide.none,
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   borderSide:
  //                       const BorderSide(color: Color(0xFF1976D2), width: 2),
  //                 ),
  //                 prefixIcon: Container(
  //                   padding: const EdgeInsets.all(12),
  //                   child:
  //                       const Icon(Icons.description, color: Color(0xFF1976D2)),
  //                 ),
  //                 contentPadding: const EdgeInsets.symmetric(vertical: 16),
  //                 labelStyle: const TextStyle(color: Color(0xFF1976D2)),
  //               ),
  //             ),
  //             const SizedBox(height: 25),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.end,
  //               children: [
  //                 TextButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   style: TextButton.styleFrom(
  //                     padding: const EdgeInsets.symmetric(
  //                         horizontal: 20, vertical: 12),
  //                   ),
  //                   child: const Text(
  //                     'Cancel',
  //                     style: TextStyle(
  //                       color: Color(0xFF1976D2),
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 ElevatedButton(
  //                   onPressed: () async {
  //                     if (teamNameController.text.trim().isNotEmpty) {
  //                       await createTeam(
  //                         teamName: teamNameController.text.trim(),
  //                         adminId: currentUser.uid,
  //                         memberIds: [currentUser.uid],
  //                       );
  //                       if (context.mounted) {
  //                         Navigator.pop(context);
  //                       }
  //                     }
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF1976D2),
  //                     foregroundColor: Colors.white,
  //                     elevation: 0,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                     padding: const EdgeInsets.symmetric(
  //                         horizontal: 24, vertical: 12),
  //                     minimumSize: const Size(120, 45),
  //                   ),
  //                   child: const Text(
  //                     'Create Team',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
