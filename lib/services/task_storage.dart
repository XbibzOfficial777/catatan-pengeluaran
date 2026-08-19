import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

class TaskStorage {
  static const _storageKey = 'task_items_v1';

  Future<List<TaskItem>> loadTasks() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <TaskItem>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskItem.fromJson)
          .toList();
    } on FormatException {
      return <TaskItem>[];
    } catch (_) {
      return <TaskItem>[];
    }
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await preferences.setString(_storageKey, raw);
  }
}
