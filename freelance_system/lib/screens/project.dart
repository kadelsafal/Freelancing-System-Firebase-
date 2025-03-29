import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/add_project.dart';
import 'package:freelance_system/freelancer/freelanced_projects.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import '../Projects/projectpost.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool isClient = true;

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Project",
              style: TextStyle(fontSize: 24),
            ),
            Row(
              mainAxisSize: MainAxisSize
                  .min, // Ensuring that the row takes only required space
              children: [
                Text(
                  isClient ? "Client Mode" : "Freelancing Mode",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 2),
                Switch(
                  value: isClient,
                  onChanged: (value) {
                    setState(() {
                      isClient = value;
                    });
                  },
                  activeTrackColor: Color.fromARGB(255, 57, 0, 98),
                  inactiveTrackColor: Color.fromARGB(255, 57, 0, 98),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) {
                      return Colors.white;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: isClient
          ? SingleChildScrollView(
              child: Column(
                children: [
                  // Show AddProject button only if in Client Mode
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color:
                                Color.fromARGB(255, 57, 0, 98), // Purple color
                            borderRadius:
                                BorderRadius.circular(50), // Circular border
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProject(),
                                ),
                              );
                            },
                            icon: Icon(Icons.add, color: Colors.white),
                            iconSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show Projectpost for Client mode
                  Center(child: Projectpost(userId: userProvider.userId)),
                ],
              ),
            )
          : FreelancedProjects(), // Show FreelancedProjects for Freelancer mode
    );
  }
}
