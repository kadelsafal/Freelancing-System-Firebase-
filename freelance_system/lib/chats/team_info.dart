import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamInfoScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamInfoScreen({
    Key? key,
    required this.teamId,
    required this.teamName,
  }) : super(key: key);

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  String? adminId;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    final userProvider = Provider.of<Userprovider>(context, listen: false);
    final teamSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .get();

    if (teamSnapshot.exists) {
      final teamData = teamSnapshot.data();
      final memberIds = List<String>.from(teamData?['members'] ?? []);
      adminId = teamData?['admin'];

      List<Map<String, dynamic>> fetchedMembers = [];

      for (var memberId in memberIds) {
        await userProvider
            .getUserDetailsById(memberId); // Fetch details for the member

        // Safely convert yearsOfExperience from String to int
        int yearsOfExperience =
            int.tryParse(userProvider.yearsOfExperience) ?? 0;

        // Get the rating based on years of experience
        double experienceRating = getExperienceRating(yearsOfExperience);

        var member = {
          'id': memberId,
          'fullName': userProvider.userName,
          'isAdmin': memberId == adminId,
          'experienceRating': experienceRating,
        };

        fetchedMembers.add(member);
      }

      setState(() {
        members = fetchedMembers;
        isLoading = false;
      });
    }
  }

  double getExperienceRating(int yearsOfExperience) {
    if (yearsOfExperience >= 10) {
      return 5.0;
    } else if (yearsOfExperience >= 5) {
      return 4.0;
    } else if (yearsOfExperience >= 2) {
      return 3.0;
    } else if (yearsOfExperience >= 1) {
      return 2.0;
    } else {
      return 0.0;
    }
  }

  Widget _buildRatingStars(double rating) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemSize: 20,
      itemCount: 5,
      itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
      itemBuilder: (context, _) =>
          Icon(Icons.star, size: 20, color: Colors.amber),
      onRatingUpdate: (rating) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.teamName.toUpperCase()} Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? Center(child: Text("No team members found."))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    itemCount: members.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isAdmin = member['isAdmin'] == true;
                      final experienceRating = member['experienceRating'];

                      return Card(
                        color: isAdmin ? Colors.deepPurple : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    isAdmin ? Colors.white : Colors.deepPurple,
                                child: Text(
                                  member['fullName'].isNotEmpty
                                      ? member['fullName'][0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: isAdmin
                                        ? const Color.fromARGB(255, 69, 0, 189)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                member['fullName'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isAdmin ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              // Displaying rating as stars
                              _buildRatingStars(experienceRating),
                              SizedBox(height: 25),
                              Container(
                                width: 100,
                                padding: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.white
                                      : Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isAdmin
                                        ? const Color.fromARGB(
                                            255, 255, 255, 255)
                                        : Colors.deepPurple,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    isAdmin ? 'Admin' : 'Member',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isAdmin
                                          ? Colors.deepPurple
                                          : const Color.fromARGB(
                                              255, 255, 255, 255),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
