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

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  // Load image from local path
  Future<void> _loadImage() async {
    if (widget.resume.imageUrl != null && widget.resume.imageUrl!.isNotEmpty) {
      final file = File(widget.resume.imageUrl!);
      if (await file.exists()) {
        imageBytes = await file.readAsBytes();
        setState(() {
          createPdf(); // Recreate the PDF after image is loaded
        });
      }
    } else {
      imageBytes = null;
      setState(() {
        createPdf();
      });
    }
  }

  void createPdf() {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
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
      ),
    );
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
              child: imageBytes != null
                  ? pw.Image(
                      pw.MemoryImage(imageBytes!),
                      fit: pw.BoxFit.cover,
                    )
                  : pw.Center(
                      child: pw.Text(
                        "No Image",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
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
          pw.Center(
            child: pw.Text("📧  ${widget.resume.email}",
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.SizedBox(height: 7),
          pw.Center(
            child: pw.Text("📞  ${widget.resume.phone}",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                )),
          ),
          pw.SizedBox(height: 7),
          pw.Center(
            child: pw.Column(
              children: widget.resume.address?.map((addr) {
                    return pw.Padding(
                      padding: pw.EdgeInsets.only(
                          bottom: 10), // Add space between each address
                      child: pw.Text("📍 ${addr}",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          )),
                    );
                  }).toList() ??
                  [], // If address is null, return an empty list
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.white, thickness: 2),
          pw.SizedBox(height: 20),
          sectionTitle("Skills"),
          pw.SizedBox(height: 15),
          pw.Column(
            children: widget.resume.skills?.map((skill) {
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
                    pw.Text("${exp.company}",
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text("${exp.position}",
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
                    pw.Text("${exp.description}",
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
                    pw.Text("${edu.institution}",
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text("${edu.description}",
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black)),
                    pw.SizedBox(height: 8),
                    pw.Text("${edu.degree}",
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
        title: Text("Resume Preview"),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: () async {
              Directory? dir = await getExternalStorageDirectory();
              File file = File("${dir!.path}/resume.pdf");

              await file.writeAsBytes(await pdf.save());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("PDF Saved Successfully"),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: "Open",
                    onPressed: () async {
                      await OpenFile.open(file.path);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              Uint8List bytes = await pdf.save();
              await Printing.layoutPdf(onLayout: (format) => bytes);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200], // Light gray background like a scanner
        padding: EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: FutureBuilder<Uint8List>(
              future: pdf.save(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error generating PDF"));
                } else {
                  return PdfPreview(
                    build: (format) => snapshot.data!,
                    allowSharing: true,
                    allowPrinting: true,
                    canChangePageFormat: false, // Keeps the format fixed
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
