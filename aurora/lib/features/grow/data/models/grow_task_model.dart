/// Modelo de datos para una tarea diaria del cultivo.
library;

class GrowTaskModel {
  final String id;
  final String growId;
  final int day;
  final String action;
  final String detail;
  final String priority;
  final String category;
  final bool isCompleted;
  final DateTime? completedAt;

  const GrowTaskModel({
    required this.id,
    required this.growId,
    required this.day,
    required this.action,
    required this.detail,
    required this.priority,
    required this.category,
    required this.isCompleted,
    this.completedAt,
  });

  factory GrowTaskModel.fromJson(Map<String, dynamic> json) {
    return GrowTaskModel(
      id: json['id'] as String? ?? '',
      growId: json['grow_id'] as String? ?? '',
      day: json['day'] as int? ?? 1,
      action: json['action'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'maintenance',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grow_id': growId,
      'day': day,
      'action': action,
      'detail': detail,
      'priority': priority,
      'category': category,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Icono según la categoría de la tarea.
  String get categoryIcon {
    switch (category) {
      case 'nutrition':
        return '🧪';
      case 'training':
        return '✂️';
      case 'observation':
        return '👁️';
      case 'maintenance':
      default:
        return '🔧';
    }
  }

  /// Si la tarea es de alta prioridad o crítica.
  bool get isHighPriority => priority == 'high' || priority == 'critical';

  GrowTaskModel copyWith({
    String? id,
    String? growId,
    int? day,
    String? action,
    String? detail,
    String? priority,
    String? category,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return GrowTaskModel(
      id: id ?? this.id,
      growId: growId ?? this.growId,
      day: day ?? this.day,
      action: action ?? this.action,
      detail: detail ?? this.detail,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
