import 'package:flutter/material.dart';

class DescriptionWidget extends StatefulWidget {
  final String description;

  const DescriptionWidget({super.key, required this.description});

  @override
  State<DescriptionWidget> createState() => _DescriptionWidgetState();
}

class _DescriptionWidgetState extends State<DescriptionWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 231, 254),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textSpan = TextSpan(
              text: widget.description,
              style: const TextStyle(
                color: Color.fromARGB(255, 35, 35, 35),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            );

            final textPainter = TextPainter(
              text: textSpan,
              maxLines: 5,
              textDirection: TextDirection.ltr,
            );

            textPainter.layout(maxWidth: constraints.maxWidth);

            final exceedsMaxLines = textPainter.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpanded
                      ? widget.description
                      : _getTruncatedText(widget.description, 5),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                if (exceedsMaxLines)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Text(isExpanded ? "Less" : "... More",
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getTruncatedText(String text, int maxLines) {
    final words = text.split(' ');
    if (words.length <= maxLines * 5) {
      return text; // Roughly estimate words per line
    }

    return '${words.take(maxLines * 5).join(' ')}...';
  }
}
