part of 'todo_tool_screen.dart';

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
    this.category,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? category;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
    );
  }
}
