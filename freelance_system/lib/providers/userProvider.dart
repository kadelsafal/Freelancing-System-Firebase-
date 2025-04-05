import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Userprovider extends ChangeNotifier {
  String userName = "";
  String userEmail = "";
  String userId = "";
  String userphn = "";
  String followers = "";
  String followed = "";

  // Adding the new fields for resume_entities
  Map<String, dynamic> resumeEntities = {};
  String yearsOfExperience = "";
  // Resume-related fields
  List<String> collegeName = [];
  List<String> companiesWorkedAt = [];
  List<String> degree = [];
  List<String> duration = [];
  List<String> name = [];
  List<String> skills = [];
  List<String> university = [];
  List<String> workedAs = [];

  var db = FirebaseFirestore.instance;

  // Fetch details for the currently authenticated user
  Future<void> getUserDetails() async {
    var authUser = FirebaseAuth.instance.currentUser;

    await db.collection('users').doc(authUser!.uid).get().then((dataSnapshot) {
      // User details
      userName = dataSnapshot.data()?["Full Name"] ?? "";
      userEmail = dataSnapshot.data()?["email"] ?? "";
      userId = dataSnapshot.data()?["id"] ?? "";
      userphn = dataSnapshot.data()?["phone"] ?? "";
      followed = (dataSnapshot.data()?["followed"] ?? 0).toString();
      followers = (dataSnapshot.data()?["followers"] ?? 0).toString();

      // Resume entities
      resumeEntities = dataSnapshot.data()?["resume_entities"] ?? {};

      collegeName = List<String>.from(resumeEntities["COLLEGE NAME"] ?? []);
      companiesWorkedAt =
          List<String>.from(resumeEntities["COMPANIES WORKED AT"] ?? []);
      degree = List<String>.from(resumeEntities["DEGREE"] ?? []);
      duration = List<String>.from(resumeEntities["DURATION"] ?? []);
      name = List<String>.from(resumeEntities["NAME"] ?? []);
      skills = List<String>.from(resumeEntities["SKILLS"] ?? []);
      university = List<String>.from(resumeEntities["UNIVERSITY"] ?? []);
      workedAs = List<String>.from(resumeEntities["WORKED AS"] ?? []);
      yearsOfExperience =
          (resumeEntities["YEARS OF EXPERIENCE"] ?? []).isNotEmpty
              ? resumeEntities["YEARS OF EXPERIENCE"][0]
              : "";

      notifyListeners();
    });
  }

  // Fetch details for any other user based on userId
  Future<void> getUserDetailsById(String otherUserId) async {
    await db.collection('users').doc(otherUserId).get().then((dataSnapshot) {
      userName = dataSnapshot.data()?["Full Name"] ?? "";
      userEmail = dataSnapshot.data()?["email"] ?? "";
      userId = dataSnapshot.data()?["id"] ?? "";
      userphn = dataSnapshot.data()?["phone"] ?? "";
      followed = (dataSnapshot.data()?["followed"] ?? 0).toString();
      followers = (dataSnapshot.data()?["followers"] ?? 0).toString();

      // Resume entities
      resumeEntities = dataSnapshot.data()?["resume_entities"] ?? {};

      collegeName = List<String>.from(resumeEntities["COLLEGE NAME"] ?? []);
      companiesWorkedAt =
          List<String>.from(resumeEntities["COMPANIES WORKED AT"] ?? []);
      degree = List<String>.from(resumeEntities["DEGREE"] ?? []);
      duration = List<String>.from(resumeEntities["DURATION"] ?? []);
      name = List<String>.from(resumeEntities["NAME"] ?? []);
      skills = List<String>.from(resumeEntities["SKILLS"] ?? []);
      university = List<String>.from(resumeEntities["UNIVERSITY"] ?? []);
      workedAs = List<String>.from(resumeEntities["WORKED AS"] ?? []);
      yearsOfExperience =
          (resumeEntities["YEARS OF EXPERIENCE"] ?? []).isNotEmpty
              ? resumeEntities["YEARS OF EXPERIENCE"][0]
              : "";

      notifyListeners();
    });
  }
}
