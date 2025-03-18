import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';

class PaymentSystem extends StatefulWidget {
  const PaymentSystem({super.key});

  @override
  State<PaymentSystem> createState() => _PaymentSystemState();
}

class _PaymentSystemState extends State<PaymentSystem> {
  String extractedExperience = "No experience extracted yet.";
  bool isLoading = false;

  Future<void> pickAndExtractExperience() async {
    setState(() {
      isLoading = true;
    });

    // Step 1: Pick a PDF file
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) {
      setState(() {
        isLoading = false;
      });
      return; // User canceled the picker
    }

    File pdfFile = File(result.files.single.path!);

    // Step 2: Extract experience section
    String experienceText = await extractExperienceFromPdf(pdfFile.path);

    // Step 3: Store extracted experience in Firestore
    await storeExperienceInFirestore("user123", experienceText);

    setState(() {
      extractedExperience = experienceText;
      isLoading = false;
    });
  }

  Future<String> extractExperienceFromPdf(String pdfPath) async {
    try {
      // Load the PDF document
      final File file = File(pdfPath);
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from the entire document
      String fullText = PdfTextExtractor(document).extractText();
      print("Full Text from PDF:");
      print(fullText); // Debugging: print full text to understand the structure

      // Close the document
      document.dispose();

      // Extract "Experience" section using regex
      RegExp exp = RegExp(
        r'Experience[\s\S]*?(?=(Education|Skills|Projects|Certifications|Activities|$))',
        caseSensitive: false,
      );

      // Perform the regex match
      Match? match = exp.firstMatch(fullText);

      // Debugging: Print the extracted experience section
      String experienceSection =
          match?.group(0)?.trim() ?? "No experience section found.";
      print("Extracted Experience Section: ");
      print(experienceSection); // This will print the extracted experience
      print("---------------");

      // Optionally, print the length of the extracted section for debugging
      print("Length of Extracted Experience: ${experienceSection.length}");

      return experienceSection;
    } catch (e) {
      return "Error extracting experience: $e";
    }
  }

  Future<void> storeExperienceInFirestore(
      String userId, String experience) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(userId).set({
      'experience': experience,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Experience Extractor')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isLoading ? null : pickAndExtractExperience,
                child: isLoading
                    ? CircularProgressIndicator()
                    : Text('Select PDF & Extract Experience'),
              ),
              SizedBox(height: 20),
              Text(
                extractedExperience,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
