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
    try {
      await _loadImage();
      print("Image loaded successfully.");

      await _generatePdf();
      print("PDF generated successfully.");

      await _generatePdfImage();
      print("PDF image generated successfully.");
    } catch (e) {
      print("Error generating PDF: $e");
    }

    setState(() {}); // Ensure UI updates
  }

  Future<void> _loadImage() async {
    if (widget.resume.imageUrl.isNotEmpty) {
      try {
        final file = File(widget.resume.imageUrl);
        if (await file.exists()) {
          resumeImageBytes = await file.readAsBytes();
        } else {
          print("---Image file does not exist at: ${widget.resume.imageUrl}");
        }
      } catch (e) {
        print("Failed to load image: $e");
      }
    } else {
      print("No image URL provided.");
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
  @override
  Widget build(BuildContext context) {
    // Wait only for PDF image, not resume image
    if (pdfImageBytes == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Generating PDF...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Preview(
      pdfimageBytes: pdfImageBytes,
      pdf: pdf,
    );
  }
}
