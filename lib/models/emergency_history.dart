import 'package:hive/hive.dart';
import 'package:sos1/models/sos_incident.dart';

part 'emergency_history.g.dart';

@HiveType(typeId: 4)
class EmergencyHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String status;

  @HiveField(3)
  final DateTime startedAt;

  @HiveField(4)
  final DateTime? resolvedAt;

  @HiveField(5)
  final String? responderType;

  @HiveField(6)
  final int? etaMinutes;

  @HiveField(7)
  final String? notes;

  EmergencyHistory({
    required this.id,
    required this.type,
    required this.status,
    required this.startedAt,
    this.resolvedAt,
    this.responderType,
    this.etaMinutes,
    this.notes,
  });

  factory EmergencyHistory.fromJson(Map<String, dynamic> json) {
    return EmergencyHistory(
      id: json['id'],
      type: json['type'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      startedAt:
          DateTime.parse(json['started_at'] ?? json['startedAt']).toLocal(),
      resolvedAt: json['resolved_at'] != null || json['resolvedAt'] != null
          ? DateTime.parse(json['resolved_at'] ?? json['resolvedAt']).toLocal()
          : null,
      responderType: json['responder_type'] ?? json['responderType'],
      etaMinutes: json['eta_minutes'] ?? json['etaMinutes'],
      notes: json['notes'],
    );
  }

  factory EmergencyHistory.fromSOSIncident(SOSIncident incident) {
    return EmergencyHistory(
      id: incident.id,
      type: incident.type
          .name, // enum -> string, e.g. "medical", "fire", "security", "other"
      status: incident.status,
      startedAt: incident.timestamp,
      resolvedAt: incident.status == 'completed' ? incident.timestamp : null,
      responderType: null,
      etaMinutes: null,
      notes: incident.details,
    );
  }
}
