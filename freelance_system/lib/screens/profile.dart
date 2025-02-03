import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile_controller/bottomsheet_profile.dart';
import 'package:freelance_system/screens/splash_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../profile_controller/showAddPostDialog.dart';
import '../profile_controller/mypost.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _userRating =
      4.5; // Default rating, replace with dynamic value if needed

  String getRatingText(double rating) {
    if (rating >= 4.5) return "Excellent";
    if (rating >= 3.5) return "Good";
    if (rating >= 2.5) return "Average";
    if (rating >= 1.5) return "Beginner";
    return "Poor";
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Profile"),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                child: Text(
                  userProvider.userName[0],
                  style: TextStyle(fontSize: 48),
                ),
              ),
              SizedBox(height: 20),
              Text(
                userProvider.userName.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              SizedBox(height: 15),
              Text(userProvider.userId),
              Text(userProvider.userphn),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return BottomsheetProfile();
                      });
                },
                child: Text("Edit profile"),
              ),
              SizedBox(height: 20),
              // Followers, Followed, and Projects with Vertical Lines
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        userProvider
                            .followers, // Replace with actual follower count
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text("Followers"),
                    ],
                  ),
                  Container(
                    height: 40, // Height of the vertical line
                    width: 1, // Width of the vertical line
                    color: Colors.grey,
                  ),
                  Column(
                    children: [
                      Text(
                        userProvider
                            .followed, // Replace with actual followed count
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text("Followed"),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey,
                  ),
                  Column(
                    children: [
                      Text(
                        "10", // Replace with actual project count
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text("Projects"),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Rating Stars
              Column(
                children: [
                  Text(
                    "Your Rating:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  RatingBar.builder(
                    initialRating: _userRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemSize: 20, // Adjusted size
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _userRating = rating;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    getRatingText(
                        _userRating), // Displays rating text dynamically
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Rated: ${_userRating.toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              // Add a Status/Post Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add a Status / Post",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          child: Text(
                            userProvider.userName[0],
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return const ShowAddPostDialog(); // Display your custom dialog
                                },
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "What's on your mind?",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
              ),
              //Add a Mypost section
              MyPost(userId: userProvider.userId),
            ],
          ),
        ),
      ),
    );
  }
}
