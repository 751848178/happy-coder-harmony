part of 'reducer.dart';

class Todo {
  Todo({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.createdAt,
    this.completedAt,
    this.tags,
  });

  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final List<String>? tags;

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'completed': completed,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (tags != null) 'tags': tags,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
    );
  }
}

class LatestUsage {
  LatestUsage({
    this.tool,
    this.function,
    this.lastUsed,
  });

  final String? tool;
  final String? function;
  final DateTime? lastUsed;

  factory LatestUsage.fromJson(Map<String, dynamic> json) {
    return LatestUsage(
      tool: json['tool'] as String?,
      function: json['function'] as String?,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tool != null) 'tool': tool,
      if (function != null) 'function': function,
      if (lastUsed != null) 'lastUsed': lastUsed!.toIso8601String(),
    };
  }
}

class OpenTurn {
  OpenTurn({
    required this.id,
    required this.startedAt,
    this.status,
    this.messages,
  });

  final String id;
  final DateTime startedAt;
  final String? status;
  final List<ReducerMessage>? messages;

  factory OpenTurn.fromJson(Map<String, dynamic> json) {
    return OpenTurn(
      id: json['id'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      status: json['status'] as String?,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((item) => ReducerMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      if (status != null) 'status': status,
      if (messages != null)
        'messages': messages!.map((message) => message.toJson()).toList(),
    };
  }
}
