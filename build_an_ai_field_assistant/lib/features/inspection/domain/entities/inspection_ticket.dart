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
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSynced => status == 'synced';
  bool get isPendingSync => status == 'pending_sync';

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
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ updatedAt.hashCode;
}
