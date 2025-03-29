import 'package:flutter/material.dart';

class EditResumeEntitiesDialog extends StatefulWidget {
  final Map<String, dynamic> entities;
  final Function(Map<String, dynamic>) onSubmit;

  const EditResumeEntitiesDialog({
    required this.entities,
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  _EditResumeEntitiesDialogState createState() =>
      _EditResumeEntitiesDialogState();
}

class _EditResumeEntitiesDialogState extends State<EditResumeEntitiesDialog> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var key in widget.entities.keys)
        key: TextEditingController(text: widget.entities[key].join(", "))
    };
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _submitChanges() {
    Map<String, dynamic> updatedEntities = {
      for (var key in _controllers.keys)
        key: _controllers[key]!.text.split(", ").map((e) => e.trim()).toList()
    };
    widget.onSubmit(updatedEntities);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Resume Details"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitChanges,
          child: Text("Submit"),
        ),
      ],
    );
  }
}
