import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/applicants/applicant_details.dart';
import 'package:freelance_system/Projects/applicants/freelancer_service.dart';

class Applicants extends StatefulWidget {
  final Map<String, dynamic> applicant;
  final String projectId;

  const Applicants(
      {super.key, required this.applicant, required this.projectId});

  @override
  State<Applicants> createState() => _ApplicantsState();
}

class _ApplicantsState extends State<Applicants> {
  bool isLoading = false;
  Map<String, dynamic>? projectData;

  @override
  void initState() {
    super.initState();
    fetchProjectData();
  }

  Future<void> fetchProjectData() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (doc.exists) {
      setState(() {
        projectData = doc.data();
      });
    }
  }

  Future<void> appointFreelancer(String name, String id) async {
    setState(() => isLoading = true);
    try {
      await FreelancerService.appointFreelancer(
        context: context,
        projectId: widget.projectId,
        freelancerName: name,
        freelancerId: id,
        projectData: projectData!,
      );
      Navigator.pop(context);
    } catch (_) {
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (projectData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Applicant Details")),
      body: ApplicantDetails(
        applicant: widget.applicant,
        projectData: projectData!,
        isLoading: isLoading,
        onAppoint: appointFreelancer,
      ),
    );
  }
}
