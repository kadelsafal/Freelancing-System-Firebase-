import 'package:flutter/material.dart';

class Recommended extends StatelessWidget {
  final List<dynamic> recommended;

  const Recommended({super.key, required this.recommended});

  @override
  Widget build(BuildContext context) {
    return recommended.isNotEmpty
        ? ListView.builder(
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              var candidate = recommended[index];
              String name = candidate['name'] ?? 'Unknown';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                title: Text(name),
                subtitle: Text("Click to view details"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to recommended candidate details
                },
              );
            },
          )
        : Center(child: Text("No recommended applicants"));
  }
}
