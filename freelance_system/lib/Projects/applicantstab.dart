import 'package:flutter/material.dart';

class AllApplicants extends StatelessWidget {
  final List<dynamic> applicants;

  const AllApplicants({super.key, required this.applicants});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: applicants.length,
      itemBuilder: (context, index) {
        var applicant = applicants[index];
        String name = applicant['name'] ?? 'Unknown';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Text(name.isNotEmpty ? name[0] : '?',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          title: Text(name),
          subtitle: Text("Click to view details"),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to applicant details
          },
        );
      },
    );
  }
}
