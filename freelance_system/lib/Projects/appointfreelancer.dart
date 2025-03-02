import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Appointfreelancer extends StatefulWidget {
  final String projectId;
  const Appointfreelancer({super.key, required this.projectId});

  @override
  State<Appointfreelancer> createState() => _AppointfreelancerState();
}

class _AppointfreelancerState extends State<Appointfreelancer> {
  List<Map<String, dynamic>> appliedIndividuals =
      []; // List of applied individuals
  Map<String, dynamic>? selectedFreelancer; // Store selected freelancer

  @override
  void initState() {
    super.initState();
    // Fetch applied individuals for the project
    fetchAppliedIndividuals();
  }

  Future<void> fetchAppliedIndividuals() async {
    try {
      DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectSnapshot.exists) {
        List<dynamic> appliedList = projectSnapshot['appliedIndividuals'] ?? [];
        setState(() {
          appliedIndividuals = List<Map<String, dynamic>>.from(appliedList);
        });
      }
    } catch (e) {
      print("Error fetching applied individuals: $e");
    }
  }

  Future<void> appointFreelancer() async {
    if (selectedFreelancer != null) {
      try {
        // Update project document with appointed freelancer details
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update({
          'appointedFreelancer': selectedFreelancer!['name'],
          'appointedFreelancerId': selectedFreelancer!['userId'],
        });

        // Close the modal sheet
        Navigator.pop(context);
      } catch (e) {
        print("Error appointing freelancer: $e");
      }
    } else {
      // Show an error message if no freelancer is selected
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select a freelancer to appoint"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Freelancer to Appoint",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // List of applied individuals
          if (appliedIndividuals.isNotEmpty) ...[
            // Make the list scrollable if more than 5 individuals
            SizedBox(
              height: appliedIndividuals.length > 5
                  ? 300.0 // Set a fixed height for large lists
                  : null,
              child: SingleChildScrollView(
                child: Column(
                  children: appliedIndividuals.map((applicant) {
                    String name = applicant['name'] ?? 'Unknown';
                    String userId = applicant['userId'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      title: Text(name),
                      trailing: Radio<Map<String, dynamic>>(
                        value: applicant,
                        groupValue: selectedFreelancer,
                        onChanged: (Map<String, dynamic>? value) {
                          setState(() {
                            selectedFreelancer = value;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: appointFreelancer,
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                  foregroundColor: MaterialStateProperty.all(Colors.white)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Appoint Freelancer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            Center(child: Text("No applicants available")),
          ]
        ],
      ),
    );
  }
}
