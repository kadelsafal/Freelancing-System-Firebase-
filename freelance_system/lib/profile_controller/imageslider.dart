import 'package:flutter/material.dart';

class Imageslider extends StatefulWidget {
  final List<String> imageUrls;

  const Imageslider({required this.imageUrls, super.key});

  @override
  State<Imageslider> createState() => _ImagesliderState();
}

class _ImagesliderState extends State<Imageslider> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to dynamically adjust the height of the image slider
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Container(
          height: screenHeight *
              0.4, // Adjust height as a percentage of the screen height
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.network(
                  widget.imageUrls[index],
                  width: double.infinity,
                  fit: BoxFit.contain, // Ensures the entire image is visible
                ),
              );
            },
          ),
        ),
        SizedBox(height: 5), // Increased spacing for better layout
        if (widget.imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                height: 10, // Slightly larger indicators
                width: _currentPage == index ? 20 : 10,
                decoration: BoxDecoration(
                  color:
                      _currentPage == index ? Colors.deepPurple : Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
