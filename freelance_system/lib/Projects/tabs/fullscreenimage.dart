import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String url;

  const FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Screen Image"),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}
