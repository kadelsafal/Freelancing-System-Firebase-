import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/tabs/status/status_list.dart';

import 'package:provider/provider.dart';
import 'package:freelance_system/providers/userProvider.dart';

import 'status_input_field.dart';

class StatusTab extends StatelessWidget {
  final String projectId;
  final String role;

  const StatusTab({super.key, required this.projectId, required this.role});

  @override
  Widget build(BuildContext context) {
    final currentName = Provider.of<Userprovider>(context).userName;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
              child:
                  StatusList(projectId: projectId, currentName: currentName)),
          StatusInputWrapper(
            projectId: projectId,
            currentName: currentName,
            role: role,
          ),
        ],
      ),
    );
  }
}
