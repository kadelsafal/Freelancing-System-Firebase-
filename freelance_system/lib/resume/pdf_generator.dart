import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freelance_system/resume/preview.dart';
import 'package:freelance_system/resume/resume_modal.dart';
import 'package:freelance_system/resume/pdf_generator.dart';
import 'package:freelance_system/resume/templates/modern_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class PdfGenerator extends StatefulWidget {
  final Resume resume;
  final String selectedTemplate;

  const PdfGenerator(
      {super.key, required this.resume, required this.selectedTemplate});

  @override
  State<PdfGenerator> createState() => _PdfGeneratorState();
}

class _PdfGeneratorState extends State<PdfGenerator> {
  final pdf = pw.Document();
  Uint8List? pdfImageBytes;
  Uint8List? resumeImageBytes;

  @override
  void initState() {
    super.initState();
    _loadImageAndGeneratePdf();
  }

  Future<void> _loadImageAndGeneratePdf() async {
    // Load the image from the resume's imageUrl
    await _loadImage();

    // Once the image is loaded, generate the PDF
    await _generatePdf();

    // After the PDF is generated, generate the image for preview
    await _generatePdfImage();

    setState(() {}); // Update the UI once both PDF and image are ready
  }

  Future<void> _loadImage() async {
    if (widget.resume.imageUrl.isNotEmpty) {
      try {
        // Load the image from a local file path
        final file =
            File(widget.resume.imageUrl); // Use File to read local files
        resumeImageBytes = await file.readAsBytes();
      } catch (e) {
        // Handle image loading failure
        print("Failed to load image: $e");
      }
    }
  }

  Future<void> _generatePdf() async {
    // Check the selected template and generate the corresponding PDF
    if (widget.selectedTemplate == "Modern Template") {
      await _generateModernTemplate();
    }
  }

  Future<void> _generateModernTemplate() async {
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return ModernTemplate.buildResumeTemplate(context, widget.resume,
            imageBytes: resumeImageBytes);
      },
    ));
  }

  Future<void> _generatePdfImage() async {
    // Save the PDF and convert it into an image
    final pdfBytes = await pdf.save();
    final pages = Printing.raster(pdfBytes, pages: [0], dpi: 150);

    // Extract the first page image and convert to PNG
    final firstPage = await pages.first;
    final pngBytes = await firstPage.toPng();

    setState(() {
      pdfImageBytes = pngBytes; // Store the generated image bytes
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if the image bytes are not yet available
    if (pdfImageBytes == null || resumeImageBytes == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Generating PDF...'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Once the image and PDF are ready, pass the image and PDF to the Preview widget
    return Preview(
      pdfimageBytes: pdfImageBytes,
      pdf: pdf,
    );
  }
}
