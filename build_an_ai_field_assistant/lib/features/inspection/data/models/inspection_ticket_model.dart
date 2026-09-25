import 'dart:convert';
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
    super.imagePath,
    super.equipmentId,
    super.detectedIssues = const [],
    super.requiredParts = const [],
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
      imagePath: entity.imagePath,
      equipmentId: entity.equipmentId,
      detectedIssues: entity.detectedIssues,
      requiredParts: entity.requiredParts,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Helper to safely parse detected issues
  static List<String> _parseIssues(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        return [raw.trim()];
      }
    }
    return const [];
  }

  /// Helper to safely parse required parts
  static List<InspectionPart> _parseParts(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          return InspectionPart.fromJson(Map<String, dynamic>.from(e));
        }
        return InspectionPart(name: e.toString());
      }).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return _parseParts(decoded);
        }
      } catch (_) {
        return [InspectionPart(name: raw.trim())];
      }
    }
    return const [];
  }

  /// Create model from JSON (API / Remote DS / Gemini AI Structured Output)
  factory InspectionTicketModel.fromJson(
    Map<String, dynamic> json, {
    String? rawTranscript,
    String? audioPath,
    String? imagePath,
  }) {
    final now = DateTime.now();
    return InspectionTicketModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Biên bản kiểm tra hiện trường',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? 'Chưa xác định vị trí',
      category: (json['category'] as String? ?? 'general').toLowerCase(),
      priority: (json['priority'] as String? ?? 'medium').toLowerCase(),
      status: json['status'] as String? ?? 'pending',
      suggestedAction: json['suggested_action'] as String? ?? '',
      inspectorName: json['inspector_name'] as String? ?? 'Kỹ sư hiện trường',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.95,
      rawTranscript: rawTranscript ?? json['raw_transcript'] as String?,
      audioPath: audioPath ?? json['audio_path'] as String?,
      imagePath: imagePath ?? json['image_path'] as String?,
      equipmentId: (json['equipment_id'] ?? json['equipmentId']) as String?,
      detectedIssues: _parseIssues(json['detected_issues'] ?? json['detectedIssues']),
      requiredParts: _parseParts(json['required_parts'] ?? json['requiredParts']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : now,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : now,
    );
  }

  /// Factory directly from Gemini AI extracted JSON
  factory InspectionTicketModel.fromAiExtraction(
    Map<String, dynamic> map, {
    String? rawTranscript,
    String? audioPath,
    String? imagePath,
  }) {
    final now = DateTime.now();
    return InspectionTicketModel(
      id: const Uuid().v4(),
      title: map['title'] as String? ?? 'Biên bản kiểm tra hiện trường',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? 'Chưa xác định vị trí',
      category: (map['category'] as String? ?? 'general').toLowerCase(),
      priority: (map['priority'] as String? ?? 'medium').toLowerCase(),
      status: 'pending',
      suggestedAction: map['suggested_action'] as String? ?? '',
      inspectorName: map['inspector_name'] as String? ?? 'Kỹ sư hiện trường',
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0.95,
      rawTranscript: rawTranscript,
      audioPath: audioPath,
      imagePath: imagePath ?? map['image_path'] as String?,
      equipmentId: (map['equipment_id'] ?? map['equipmentId']) as String?,
      detectedIssues: _parseIssues(map['detected_issues'] ?? map['detectedIssues']),
      requiredParts: _parseParts(map['required_parts'] ?? map['requiredParts']),
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
      'image_path': imagePath,
      'equipment_id': equipmentId,
      'detected_issues': detectedIssues,
      'required_parts': requiredParts.map((p) => p.toJson()).toList(),
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
      imagePath: map['image_path'] as String?,
      equipmentId: map['equipment_id'] as String?,
      detectedIssues: _parseIssues(map['detected_issues']),
      requiredParts: _parseParts(map['required_parts']),
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
      'image_path': imagePath,
      'equipment_id': equipmentId,
      'detected_issues': jsonEncode(detectedIssues),
      'required_parts': jsonEncode(requiredParts.map((p) => p.toJson()).toList()),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
