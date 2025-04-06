import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelance_system/providers/userProvider.dart';

class StatusTab extends StatefulWidget {
  final String projectId;
  const StatusTab({super.key, required this.projectId});

  @override
  _StatusTabState createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  final TextEditingController _statusUpdateController = TextEditingController();

  void _addStatusUpdate(String author, String projectId) async {
    if (_statusUpdateController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('statusUpdates')
          .add({
        'author': author,
        'text': _statusUpdateController.text,
        'role': 'freelancer',
        'timestamp': Timestamp.now(),
      });

      _statusUpdateController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status update posted successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;
    String currentUserId = userProvider.userId;

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
          var project = snapshot.data!;
          String appointedFreelancer = project['appointedFreelancer'] ?? '';

          if (currentUserId != appointedFreelancer &&
              currentUserId != project['userId']) {
            return const Center(
                child: Text("You do not have permission to post updates"));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Congrats! You are appointed as the freelancer for this project.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Status update input
                TextField(
                  controller: _statusUpdateController,
                  decoration:
                      const InputDecoration(labelText: "Post a Status Update"),
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    String author = currentName;
                    _addStatusUpdate(author, widget.projectId);
                  },
                  child: const Text("Post Update"),
                ),
                const SizedBox(height: 20),

                // StreamBuilder inside Expanded so it takes remaining height
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
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var doc = docs[index];
                            var statusData = doc.data() as Map<String, dynamic>;
                            String statusId = doc.id;

                            return ListTile(
                              title: Text(statusData['author']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(statusData['text']),
                                  Text(
                                    "Status ID: $statusId",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                  "${(statusData['timestamp'] as Timestamp).toDate()}"),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
