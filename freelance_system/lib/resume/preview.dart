import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;

class Preview extends StatefulWidget {
  final Uint8List? pdfimageBytes;
  final pw.Document pdf;
  Preview({super.key, required this.pdfimageBytes, required this.pdf});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 66, 1, 107),
        foregroundColor: Colors.white,
        title: Text(
          "PD Preview",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          InkWell(
            onTap: () async {
              Uint8List bytes = await widget.pdf.save();
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 600,
              color: Colors.transparent, // Red container background
              padding: EdgeInsets.all(10),
              child: Center(
                child: widget.pdfimageBytes == null
                    ? const CircularProgressIndicator()
                    : Container(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        child: Image.memory(
                          widget.pdfimageBytes!,
                          fit: BoxFit.contain,
                          // Ensures the image uses a white background
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () async {
                  // Get external storage directory to save the PDF
                  Directory? dir = await getExternalStorageDirectory();

                  if (dir != null) {
                    File file = File("${dir.path}/resume.pdf");

                    await file.writeAsBytes(await widget.pdf.save());

                    // Show success message with option to open the saved file
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("PDF Saved Successfully..."),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: "Open",
                          onPressed: () async {
                            await OpenFile.open(file.path);
                          },
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 66, 1, 107),
                ),
                child: Container(
                  width: 250,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Download Resume",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.save_alt,
                          size: 40,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NavigationMenu()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 66, 1, 107),
                        foregroundColor: Colors.white),
                    child: Text("Back")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
