import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class Preview extends StatefulWidget {
  final Uint8List? pdfimageBytes;
  final pw.Document pdf;
  const Preview({super.key, required this.pdfimageBytes, required this.pdf});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Resume Preview",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade700),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                Uint8List bytes = await widget.pdf.save();
                await Printing.layoutPdf(onLayout: (format) => bytes);
              },
              icon: Icon(
                Icons.print,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Preview Container
              Container(
                width: double.infinity,
                height: 600,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.pdfimageBytes == null
                      ? CircularProgressIndicator(
                          color: Colors.blue.shade700,
                        )
                      : Image.memory(
                          widget.pdfimageBytes!,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              SizedBox(height: 30),

              // Back Button
              Container(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NavigationMenu(
                          initialIndex: 1,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade700),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Back to Dashboard",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
