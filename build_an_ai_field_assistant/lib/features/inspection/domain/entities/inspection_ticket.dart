/// Linh kiện / vật tư cần thay thế hoặc sử dụng cho sự cố
class InspectionPart {
  final String name;
  final int quantity;

  const InspectionPart({
    required this.name,
    this.quantity = 1,
  });

  InspectionPart copyWith({
    String? name,
    int? quantity,
  }) {
    return InspectionPart(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  factory InspectionPart.fromJson(Map<String, dynamic> json) {
    return InspectionPart(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionPart &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity;

  @override
  int get hashCode => name.hashCode ^ quantity.hashCode;
}

/// Pure Domain Entity representing a Field Inspection Ticket
class InspectionTicket {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category; // electrical, mechanical, civil, safety, hvac, general
  final String priority; // low, medium, high, critical
  final String status; // draft, pending_sync, synced
  final String suggestedAction;
  final String inspectorName;
  final double confidenceScore;
  final String? rawTranscript;
  final String? audioPath;
  final String? equipmentId; // Mã thiết bị / phương tiện xe cơ giới
  final List<String> detectedIssues; // Danh sách các lỗi phát hiện dạng thẻ
  final List<InspectionPart> requiredParts; // Danh sách linh kiện kèm số lượng
  final DateTime createdAt;
  final DateTime updatedAt;

  const InspectionTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.priority,
    required this.status,
    required this.suggestedAction,
    this.inspectorName = 'Kỹ sư hiện trường',
    this.confidenceScore = 0.9,
    this.rawTranscript,
    this.audioPath,
    this.equipmentId,
    this.detectedIssues = const [],
    this.requiredParts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSynced => status == 'synced';
  bool get isPendingSync => status == 'pending' || status == 'pending_sync';

  InspectionTicket copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? category,
    String? priority,
    String? status,
    String? suggestedAction,
    String? inspectorName,
    double? confidenceScore,
    String? rawTranscript,
    String? audioPath,
    String? equipmentId,
    List<String>? detectedIssues,
    List<InspectionPart>? requiredParts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InspectionTicket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      inspectorName: inspectorName ?? this.inspectorName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      audioPath: audioPath ?? this.audioPath,
      equipmentId: equipmentId ?? this.equipmentId,
      detectedIssues: detectedIssues ?? this.detectedIssues,
      requiredParts: requiredParts ?? this.requiredParts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionTicket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          status == other.status &&
          equipmentId == other.equipmentId &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^ status.hashCode ^ (equipmentId?.hashCode ?? 0) ^ updatedAt.hashCode;
}
