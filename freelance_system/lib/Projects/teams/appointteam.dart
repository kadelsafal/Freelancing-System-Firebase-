import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointButton extends StatelessWidget {
  final bool isLoading;
  final String appointedTeamId;
  final String teamId;
  final String projectId;
  final String teamName;

  const AppointButton({
    super.key,
    required this.isLoading,
    required this.appointedTeamId,
    required this.teamId,
    required this.projectId,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText = "Appoint Team";
    Color buttonColor = Colors.green;
    Color textColor = Colors.white;
    bool isButtonDisabled = false;
    FontWeight textWeight = FontWeight.normal;

    if (appointedTeamId == teamId) {
      buttonText = "Appointed";
      isButtonDisabled = true;
    } else if (appointedTeamId.isNotEmpty) {
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = const Color.fromARGB(255, 255, 31, 31);
      textWeight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed:
            isButtonDisabled || isLoading ? null : () => appointTeam(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                buttonText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: textWeight,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  Future<void> appointTeam(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'appointedTeam': teamName,
        'appointedTeamId': teamId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Team Appointed!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
}
