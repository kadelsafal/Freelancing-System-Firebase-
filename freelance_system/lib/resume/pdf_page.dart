import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';

class PdfPage extends StatefulWidget {
  final Resume resume;
  const PdfPage({super.key, required this.resume});

  @override
  State<PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  final pdf = pw.Document();
  Uint8List? imageBytes;
  Uint8List? pdfimageBytes;
  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    if (widget.resume.imageUrl.isNotEmpty) {
      await _loadImage(); // Ensure image is loaded before generating the PDF
    }
    _generatePdf(); // Generate the PDF after loading the image
  }

  Future<void> _generatePdf() async {
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Container(
          width: double.infinity,
          height: double.infinity,
          padding: pw.EdgeInsets.all(0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _leftColumn(),
              pw.SizedBox(width: 20),
              _rightColumn(),
            ],
          ),
        );
      },
    ));

    setState(() {}); // Ensure UI updates after generating the PDF
    _generatePdfImage(); // Generate preview after PDF is ready
  }

  Future<void> _loadImage() async {
    final file = File(widget.resume.imageUrl);
    if (await file.exists()) {
      imageBytes = await file.readAsBytes();
      setState(() {}); // Update UI after loading the image
    }
  }

  Future<void> _generatePdfImage() async {
    final pdfBytes = await pdf.save();

    // Convert PDF bytes into images
    final pages = Printing.raster(pdfBytes, pages: [0], dpi: 150);

    // Extract the first page image
    final firstPage = await pages.first;

    // Convert to PNG format
    final pngBytes = await firstPage.toPng(); // This is the correct method

    setState(() {
      pdfimageBytes = pngBytes;
    });
  }

  pw.Widget _leftColumn() {
    return pw.Container(
      width: 200,
      height: double.infinity,
      color: PdfColors.blue,
      padding: pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (imageBytes != null)
            pw.Container(
              width: 200,
              height: 200,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.rectangle,
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(50),
              ),
              alignment: pw.Alignment.center,
              child: pw.Image(
                pw.MemoryImage(imageBytes!),
                fit: pw.BoxFit.cover,
              ),
            ),
          pw.SizedBox(height: 15),
          pw.Center(
            child: pw.Text(widget.resume.fullName,
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(" ${widget.resume.email}",
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
          pw.SizedBox(height: 7),
          pw.Text(widget.resume.phone,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              )),
          pw.SizedBox(height: 7),
          pw.Column(
            children: widget.resume.address.map((addr) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(
                        bottom: 10), // Add space between each address
                    child: pw.Text(" $addr",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  );
                }).toList() ??
                [], // If address is null, return an empty list
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.white, thickness: 2),
          pw.SizedBox(height: 20),
          sectionTitle("Skills"),
          pw.SizedBox(height: 15),
          pw.Column(
            children: widget.resume.skills.map((skill) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(
                        bottom: 10), // Add space between each address
                    child: pw.Bullet(
                        text: skill,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  );
                }).toList() ??
                [], // If address is null, return an empty list
          ),
        ],
      ),
    );
  }

  pw.Widget sectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white));
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue));
  }

  pw.Widget _rightColumn() {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle("Summary"),
          pw.SizedBox(height: 10),
          pw.Text(widget.resume.summary,
              style: pw.TextStyle(fontSize: 14, color: PdfColors.black)),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.blue, thickness: 2),
          pw.SizedBox(height: 20),
          _sectionTitle("Work Experience"),
          pw.SizedBox(height: 10),
          ...widget.resume.experiences.map((exp) => pw.Container(
                margin: pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text(exp.company,
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(exp.position,
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text("${exp.start_date} - ${exp.end_date}",
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(exp.description,
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.normal,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 10),
                  ],
                ),
              )),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.blue, thickness: 2),
          pw.SizedBox(height: 15),
          _sectionTitle("Education"),
          pw.SizedBox(height: 10),
          ...widget.resume.educations.map((edu) => pw.Container(
                margin: pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu.institution,
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(edu.course,
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text(edu.degree,
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text("${edu.start_date} - ${edu.end_date}",
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 10)
                  ],
                ),
              )),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 66, 1, 107),
        foregroundColor: Colors.white,
        title: Text(
          "PDF",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          InkWell(
            onTap: () async {
              Uint8List bytes = await pdf.save();

              await Printing.layoutPdf(onLayout: (format) => bytes);
            },
            child: const SizedBox(
              width: 120,
              child: Icon(
                Icons.print,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 700,
            color: Colors.transparent, // Red container background
            padding: EdgeInsets.all(10),
            child: Center(
              child: pdfimageBytes == null
                  ? CircularProgressIndicator()
                  : Container(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      child: Image.memory(
                        pdfimageBytes!,
                        fit: BoxFit.contain,
                        // Ensures the image uses a white background
                      ),
                    ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                Directory? dir = await getExternalStorageDirectory();

                File file = File("${dir!.path}/resume.pdf");

                await file.writeAsBytes(await pdf.save());

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("PDF Saved Successfully..."),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                        label: "Open",
                        onPressed: () async {
                          await OpenFile.open(file.path);
                        }),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 66, 1, 107), // Set the background color to purple
              ),
              child: SizedBox(
                width: 250,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Download Resume",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Icon(
                        Icons.save_alt,
                        size: 40,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
