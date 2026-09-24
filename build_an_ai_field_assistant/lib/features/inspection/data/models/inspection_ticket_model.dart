import 'package:uuid/uuid.dart';
import '../../domain/entities/inspection_ticket.dart';

/// Data Transfer Object (DTO) for InspectionTicket
class InspectionTicketModel extends InspectionTicket {
  const InspectionTicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.location,
    required super.category,
    required super.priority,
    required super.status,
    required super.suggestedAction,
    super.inspectorName,
    super.confidenceScore,
    super.rawTranscript,
    super.audioPath,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Factory from pure Domain Entity
  factory InspectionTicketModel.fromEntity(InspectionTicket entity) {
    return InspectionTicketModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      location: entity.location,
      category: entity.category,
      priority: entity.priority,
      status: entity.status,
      suggestedAction: entity.suggestedAction,
      inspectorName: entity.inspectorName,
      confidenceScore: entity.confidenceScore,
      rawTranscript: entity.rawTranscript,
      audioPath: entity.audioPath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create model from JSON (API / Remote DS)
  factory InspectionTicketModel.fromJson(Map<String, dynamic> json) {
    return InspectionTicketModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Biên bản kiểm tra chưa đặt tên',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? 'Chưa xác định vị trí',
      category: json['category'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending_sync',
      suggestedAction: json['suggested_action'] as String? ?? '',
      inspectorName: json['inspector_name'] as String? ?? 'Kỹ sư hiện trường',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.9,
      rawTranscript: json['raw_transcript'] as String?,
      audioPath: json['audio_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Factory directly from Gemini AI extracted JSON
  factory InspectionTicketModel.fromAiExtraction(
    Map<String, dynamic> map, {
    String? rawTranscript,
    String? audioPath,
  }) {
    final now = DateTime.now();
    return InspectionTicketModel(
      id: const Uuid().v4(),
      title: map['title'] as String? ?? 'Biên bản kiểm tra hiện trường',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? 'Chưa xác định vị trí',
      category: (map['category'] as String? ?? 'general').toLowerCase(),
      priority: (map['priority'] as String? ?? 'medium').toLowerCase(),
      status: 'pending_sync',
      suggestedAction: map['suggested_action'] as String? ?? '',
      inspectorName: map['inspector_name'] as String? ?? 'Kỹ sư hiện trường',
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0.95,
      rawTranscript: rawTranscript,
      audioPath: audioPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to JSON (for Remote API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'priority': priority,
      'status': status,
      'suggested_action': suggestedAction,
      'inspector_name': inspectorName,
      'confidence_score': confidenceScore,
      'raw_transcript': rawTranscript,
      'audio_path': audioPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// SQLite DB Map parser
  factory InspectionTicketModel.fromMap(Map<String, dynamic> map) {
    return InspectionTicketModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      location: map['location'] as String,
      category: map['category'] as String,
      priority: map['priority'] as String,
      status: map['status'] as String,
      suggestedAction: map['suggested_action'] as String? ?? '',
      inspectorName: map['inspector_name'] as String? ?? 'Kỹ sư hiện trường',
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0.9,
      rawTranscript: map['raw_transcript'] as String?,
      audioPath: map['audio_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to SQLite Database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'priority': priority,
      'status': status,
      'suggested_action': suggestedAction,
      'inspector_name': inspectorName,
      'confidence_score': confidenceScore,
      'raw_transcript': rawTranscript,
      'audio_path': audioPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
