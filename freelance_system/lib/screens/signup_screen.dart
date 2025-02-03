import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/screens/dashboard.dart';
import 'package:freelance_system/screens/splash_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final userForm = GlobalKey<FormState>();

  bool isloading = false;

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController first_Name = TextEditingController();
  TextEditingController last_Name = TextEditingController();
  TextEditingController phn_num = TextEditingController();
  final List<String> countryCodes = ['+1', '+977', '+44', '+61'];
  String selectedCountryCode = '+1';
  bool isPasswordVisible = false;

  Future<void> createAccount() async {
    setState(() {
      isloading = true; // Show progress indicator
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email.text, password: password.text);

      var userId = FirebaseAuth.instance.currentUser!.uid;
      // check if user is created or not
      if (userCredential.user != null) {
        //Add additional user details
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'Full Name': first_Name.text + " " + last_Name.text,
          'email': email.text,
          'phone': selectedCountryCode + phn_num.text.trim(),
          'id': userId.toString(),
          'followers': 0, // Initialize followers count
          'followed': 0, // Initialize followed count
          'rating': 0.0, // Optional: Initialize user rating
        });

        //Handle successful account creation
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Account created Successfully")));

        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) {
          return SplashScreen();
        }), (route) {
          return false;
        });
      }
    } on FirebaseAuthException catch (e) {
      //Handle specific Errors
      String errorMessage = "An error Occured";

      if (e.code == 'email-already-in-use') {
        errorMessage = 'This Email in already use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email is invalid';
      }
      //Display the error message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      //Handle any other errors
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected Error Occured, $e")));

      print(
          "-----------------------------------------------------------------error, $e");
    }
    ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SignUp"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: userForm,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // First Name Field
                        Expanded(
                          child: TextFormField(
                            controller: first_Name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "First Name is required";
                              }
                              return null;
                            },
                            decoration:
                                InputDecoration(labelText: "First Name"),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Last Name Field
                        Expanded(
                          child: TextFormField(
                            controller: last_Name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Last Name is required";
                              }
                              return null;
                            },
                            decoration: InputDecoration(labelText: "Last Name"),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Phone Number with Country Code
                    Row(
                      children: [
                        // Country Code Dropdown
                        DropdownButton<String>(
                          value: selectedCountryCode,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCountryCode = newValue!;
                            });
                          },
                          items: countryCodes
                              .map<DropdownMenuItem<String>>((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Text(code),
                            );
                          }).toList(),
                        ),
                        SizedBox(width: 10),
                        // Phone Number Field
                        Expanded(
                          child: TextFormField(
                            controller: phn_num,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Phone Number is required";
                              }
                              if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                                return "Enter a valid phone number";
                              }
                              return null;
                            },
                            keyboardType: TextInputType.phone,
                            decoration:
                                InputDecoration(labelText: "Phone Number"),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Email Field
                    TextFormField(
                      controller: email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is required";
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                      decoration: InputDecoration(labelText: "Email"),
                    ),
                    SizedBox(height: 10),
                    // Password Field with Toggle
                    TextFormField(
                      controller: password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password cannot be empty";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters long";
                        }
                        return null;
                      },
                      obscureText: !isPasswordVisible,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    isloading
                        ? CircularProgressIndicator()
                        :
                        // Sign Up Button
                        Center(
                            child: ElevatedButton(
                              onPressed: () {
                                if (userForm.currentState!.validate()) {
                                  // Handle form submission
                                  createAccount();
                                }
                              },
                              child: Text("Sign Up"),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
