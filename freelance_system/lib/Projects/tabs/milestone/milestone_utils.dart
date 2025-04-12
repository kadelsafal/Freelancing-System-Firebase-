import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneUtils {
  static String formatDate(dynamic rawDate) {
    if (rawDate == null) return "";
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is DateTime
            ? rawDate
            : DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static Color getStatusColor(String? status) {
    switch (status ?? '') {
      case 'Completed':
        return Colors.green;
      case 'Not Completed':
        return Colors.red;
      case 'In Process':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static Color getStatusTextColor(String? status) {
    switch (status ?? '') {
      case 'Completed':
      case 'Not Completed':
      case 'In Process':
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  static double calculateProjectProgress(List<DocumentSnapshot> milestones) {
    if (milestones.isEmpty) return 0;
    double total = 0;

    for (var milestone in milestones) {
      final tasks = List<Map<String, dynamic>>.from(milestone['subtasks']);
      if (tasks.isNotEmpty) {
        final done = tasks.where((e) => e['status'] == 'Completed').length;
        total += done / tasks.length;
      }
    }

    return total / milestones.length;
  }

  static Map<String, int> calculateMilestoneStats(
      List<DocumentSnapshot> milestones) {
    int completedCount = 0;
    int notCompletedCount = 0;
    int inprocessCount = 0;

    for (var milestone in milestones) {
      switch (milestone['status']) {
        case 'Completed':
          completedCount++;
          break;
        case 'Not Completed':
          notCompletedCount++;
          break;
        case 'In Process':
          inprocessCount++;
          break;
      }
    }

    return {
      'total': milestones.length,
      'completed': completedCount,
      'notCompleted': notCompletedCount,
      'inprocess': inprocessCount
    };
  }
}
