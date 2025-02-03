import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BottomsheetProfile extends StatefulWidget {
  const BottomsheetProfile({super.key});

  @override
  State<BottomsheetProfile> createState() => _BottomsheetProfileState();
}

class _BottomsheetProfileState extends State<BottomsheetProfile> {
  var editForm = GlobalKey<FormState>();
  // Controllers for TextFormField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  var db = FirebaseFirestore.instance;

  @override
  void initState() {
    _nameController.text =
        Provider.of<Userprovider>(context, listen: false).userName;
    _phoneController.text =
        Provider.of<Userprovider>(context, listen: false).userphn;
    // TODO: implement initState
    super.initState();
  }

  void updateData() async {
    try {
      // Update user profile in "users" collection
      Map<String, dynamic> userUpdate = {
        "Full Name": _nameController.text,
        "Phone Number": _phoneController.text,
      };
      await db
          .collection("users")
          .doc(Provider.of<Userprovider>(context, listen: false).userId)
          .update(userUpdate);

      // Update username in "posts" collection for all posts by the user
      QuerySnapshot postsSnapshot = await db
          .collection("posts")
          .where("userId",
              isEqualTo:
                  Provider.of<Userprovider>(context, listen: false).userId)
          .get();

      for (var doc in postsSnapshot.docs) {
        await db.collection("posts").doc(doc.id).update({
          "username": _nameController.text,
        });
      }

      // Refresh user details in the provider
      Provider.of<Userprovider>(context, listen: false).getUserDetails();

      // Close the bottom sheet
      Navigator.pop(context);
    } catch (e) {
      print("Error updating data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: editForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for "Edit Profile" title and check icon
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Space between title and icon
                children: [
                  Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (editForm.currentState!.validate()) {
                        // Update data on database
                        updateData();
                      }
                      // Add your onTap action here
                      print("Check icon tapped");
                    },
                    child: Icon(
                      Icons.check,
                      size: 35,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20), // Add space between title and content
              // Name TextFormField
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Name cannot be Empty";
                  }
                  return null;
                },
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                ),
              ),
              SizedBox(height: 20), // Space between the fields
              // Phone Number TextFormField
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Phone Number Cant be empty";
                  }
                  return null;
                },
                controller: _phoneController,
                keyboardType:
                    TextInputType.phone, // Use phone keyboard for phone number
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
