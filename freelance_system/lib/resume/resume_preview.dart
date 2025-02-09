import 'package:flutter/material.dart';
import 'package:freelance_system/resume/resume_modal.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import the PDFView package

class ResumePreviewScreen extends StatelessWidget {
  final Resume resume;

  const ResumePreviewScreen({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resume Preview")),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Details
              Row(
                children: [
                  Container(
                    color: Colors.red,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Full Name: ${resume.fullName}",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 10),
                        Text("Email: ${resume.email}",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 10),
                        Text("Phone: ${resume.phone}",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 10),
                        Text("Address: ",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: resume.address.map((address) {
                            return Text(address,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white));
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    color: Colors.yellow,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Education: ",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: resume.educations.map((edu) {
                            return Text(
                              "${edu.degree} from ${edu.institution} (${edu.start_date} to ${edu.end_date})",
                              style: TextStyle(fontSize: 16),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Summary
              Text("Summary: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(resume.summary, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),

              // Skills
              Text("Skills: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: resume.skills.map((skill) {
                  return Text(skill, style: TextStyle(fontSize: 16));
                }).toList(),
              ),
              SizedBox(height: 20),

              // Experiences
              Text("Experiences: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: resume.experiences.map((exp) {
                  return Text(
                    "${exp.position} at ${exp.company} from ${exp.start_date} to ${exp.end_date}",
                    style: TextStyle(fontSize: 16),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // Button to generate PDF
              // ElevatedButton(
              //   onPressed: () async {
              //     String pdfPath = await _generatePdf(context);
              //     _showPdf(context, pdfPath);
              //   },
              //   child: Text("Generate and View PDF"),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to generate PDF
  // Future<String> _generatePdf(BuildContext context) async {
  //   try {
  //     final PdfDocument document = PdfDocument();

  //     // Add a page to the document
  //     final PdfPage page = document.pages.add();

  //     final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
  //     final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 14,
  //         style: PdfFontStyle.bold);

  //     double yPosition = 20;
  //     page.graphics.drawString("Full Name: ${resume.fullName}", font,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;
  //     page.graphics.drawString("Email: ${resume.email}", font,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;
  //     page.graphics.drawString("Phone: ${resume.phone}", font,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;

  //     page.graphics.drawString("Address: ", boldFont,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;
  //     resume.address.forEach((address) {
  //       page.graphics.drawString(address, font,
  //           bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //       yPosition += 20;
  //     });

  //     page.graphics.drawString("Education: ", boldFont,
  //         bounds: Rect.fromLTWH(220, yPosition, 200, 20));
  //     yPosition += 25;
  //     resume.educations.forEach((edu) {
  //       page.graphics.drawString(
  //           "${edu.degree} from ${edu.institution} (${edu.start_date} to ${edu.end_date})",
  //           font,
  //           bounds: Rect.fromLTWH(220, yPosition, 200, 20));
  //       yPosition += 25;
  //     });

  //     yPosition += 20;
  //     page.graphics.drawString("Summary: ", boldFont,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;
  //     page.graphics.drawString(resume.summary, font,
  //         bounds: Rect.fromLTWH(20, yPosition, 500, 100));

  //     yPosition += 120;
  //     page.graphics.drawString("Skills: ", boldFont,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;

  //     // Adding skills as a vertical list
  //     resume.skills.forEach((skill) {
  //       page.graphics.drawString(skill, font,
  //           bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //       yPosition += 20;
  //     });

  //     yPosition += 20;
  //     page.graphics.drawString("Experiences: ", boldFont,
  //         bounds: Rect.fromLTWH(20, yPosition, 200, 20));
  //     yPosition += 25;

  //     // Adding experiences as a vertical list
  //     resume.experiences.forEach((exp) {
  //       page.graphics.drawString(
  //           "${exp.position} at ${exp.company} from ${exp.start_date} to ${exp.end_date}",
  //           font,
  //           bounds: Rect.fromLTWH(20, yPosition, 500, 20));
  //       yPosition += 25;
  //     });

  //     final List<int> bytes = await document.save();
  //     document.dispose();

  //     final directory = await getApplicationDocumentsDirectory();
  //     final file = File('${directory.path}/resume.pdf');
  //     await file.writeAsBytes(bytes);

  //     return file.path; // Return the path of the saved PDF file
  //   } catch (e) {
  //     print("Error generating PDF: $e");
  //     return "";
  //   }
  // }

  // Function to display the generated PDF in a new screen using flutter_pdfview
  void _showPdf(BuildContext context, String pdfPath) {
    if (pdfPath.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to generate PDF")));
      return;
    }

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Scaffold(
    //       appBar: AppBar(title: Text("Generated PDF")),
    //       body: PDFView(
    //         filePath: pdfPath, // Display the PDF using flutter_pdfview
    //       ),
    //     ),
    //   ),
    // );
  }
}
