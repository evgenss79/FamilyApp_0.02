import 'package:uuid/uuid.dart';

enum PendingAction { upsert, delete }

class PendingOp {
  PendingOp._({
    required this.id,
    required this.path,
    required this.action,
    this.openData,
    this.metadata,
    this.isNew = false,
    required this.createdAt,
  });

  factory PendingOp.upsert({
    required String path,
    required Map<String, dynamic> openData,
    Map<String, dynamic>? metadata,
    bool isNew = false,
  }) {
    return PendingOp._(
      id: const Uuid().v4(),
      path: path,
      action: PendingAction.upsert,
      openData: openData,
      metadata: metadata,
      isNew: isNew,
      createdAt: DateTime.now(),
    );
  }

  factory PendingOp.delete({
    required String path,
  }) {
    return PendingOp._(
      id: const Uuid().v4(),
      path: path,
      action: PendingAction.delete,
      openData: null,
      metadata: null,
      isNew: false,
      createdAt: DateTime.now(),
    );
  }

  factory PendingOp.fromMap(Map<String, dynamic> map) {
    return PendingOp._(
      id: (map['id'] ?? '').toString(),
      path: (map['path'] ?? '').toString(),
      action: PendingAction.values.firstWhere(
        (PendingAction action) => action.name == map['action'],
        orElse: () => PendingAction.upsert,
      ),
      openData: (map['openData'] as Map?)?.cast<String, dynamic>(),
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
      isNew: map['isNew'] == true,
      createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
    );
  }

  final String id;
  final String path;
  final PendingAction action;
  final Map<String, dynamic>? openData;
  final Map<String, dynamic>? metadata;
  final bool isNew;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'path': path,
        'action': action.name,
        'openData': openData,
        'metadata': metadata,
        'isNew': isNew,
        'createdAt': createdAt.toIso8601String(),
      };

  PendingOp copyWith({
    PendingAction? action,
    Map<String, dynamic>? openData,
    Map<String, dynamic>? metadata,
    bool? isNew,
  }) {
    return PendingOp._(
      id: id,
      path: path,
      action: action ?? this.action,
      openData: openData ?? this.openData,
      metadata: metadata ?? this.metadata,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt,
    );
  }
}
