import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Postprovider extends ChangeNotifier {
  String userName = "";
  String userEmail = "";
  String userId = "";
  String userphn = "";
  String userImage = "";
  var db = FirebaseFirestore.instance;

  Future<void> getUserDetails() async {
    var authUser = FirebaseAuth.instance.currentUser;
    await db.collection('posts').doc(authUser!.uid).get().then((dataSnapshot) {
      userName = dataSnapshot.data()?["Full Name"] ?? "";
      userEmail = dataSnapshot.data()?["email"] ?? "";
      userId = dataSnapshot.data()?["id"] ?? "";
      userphn = dataSnapshot.data()?["phone"] ?? "";
      userImage = dataSnapshot.data()?["profile_image"] ?? "";

      notifyListeners();
    });
  }
}
