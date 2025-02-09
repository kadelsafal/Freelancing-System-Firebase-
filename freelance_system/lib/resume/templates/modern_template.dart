import 'dart:typed_data';

import 'package:freelance_system/resume/resume_modal.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';

class ModernTemplate {
  static pw.Widget buildResumeTemplate(pw.Context context, Resume resume,
      {Uint8List? imageBytes}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _leftColumn(resume, imageBytes),
        pw.SizedBox(width: 20),
        _rightColumn(resume),
      ],
    );
  }

  static pw.Widget _leftColumn(Resume resume, Uint8List? imageBytes) {
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
              child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.cover),
            ),
          pw.SizedBox(height: 15),
          pw.Center(
            child: pw.Text(resume.fullName,
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(resume.email,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
          pw.SizedBox(height: 7),
          pw.Text(resume.phone,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
          pw.SizedBox(height: 7),
          pw.Column(
            children: resume.address?.map((addr) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 10),
                    child: pw.Text(addr,
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  );
                }).toList() ??
                [],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.white, thickness: 2),
          pw.SizedBox(height: 20),
          sectionTitle("Skills"),
          pw.SizedBox(height: 15),
          pw.Column(
            children: resume.skills?.map((skill) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 10),
                    child: pw.Bullet(
                        text: skill,
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  );
                }).toList() ??
                [],
          ),
        ],
      ),
    );
  }

  static pw.Widget _rightColumn(Resume resume) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle("Summary"),
          pw.SizedBox(height: 10),
          pw.Text(resume.summary,
              style: pw.TextStyle(fontSize: 14, color: PdfColors.black)),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.blue, thickness: 2),
          pw.SizedBox(height: 20),
          _sectionTitle("Work Experience"),
          pw.SizedBox(height: 10),
          ...resume.experiences.map((exp) => pw.Container(
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
          ...resume.educations.map((edu) => pw.Container(
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

  // Helper to generate section title
  static pw.Widget sectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white));
  }

  // Helper to generate section title with different color
  static pw.Widget _sectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue));
  }
}
