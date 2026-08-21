import 'json_helpers.dart';

enum TaskPriority { low, medium, high }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.note = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;

  TaskItem copyWith({
    String? title,
    String? note,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: readString(
        json['id'],
        fallback: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      title: readString(json['title']),
      note: readString(json['note']),
      dueDate: readNullableDate(json['dueDate']),
      priority: readEnum(
        TaskPriority.values,
        json['priority'],
        TaskPriority.medium,
      ),
      isCompleted: readBool(json['isCompleted']),
      createdAt: readDate(json['createdAt']),
    );
  }
}
