import 'package:flutter/material.dart';

class Freshers extends StatelessWidget {
  final List<dynamic> freshers;

  const Freshers({super.key, required this.freshers});

  @override
  Widget build(BuildContext context) {
    return freshers.isNotEmpty
        ? ListView.builder(
            itemCount: freshers.length,
            itemBuilder: (context, index) {
              var fresher = freshers[index];
              String name = fresher['name'] ?? 'Unknown';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                title: Text(name),
                subtitle: Text("Click to view details"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to fresher details
                },
              );
            },
          )
        : Center(child: Text("No freshers available"));
  }
}
