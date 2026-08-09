// NEW file — data model for an officer-initiated emergency resolution
// received via the EMERGENCY_RESOLVED SSE event.

/// Maps to the `emergency` object inside the EMERGENCY_RESOLVED SSE payload.
class EmergencyResolution {
  final String emergencyId;
  final String status; // "resolved" | "false_alarm"
  final String? responderType; // "police" | "samu" | "fire" | "other"
  final int? etaMinutes;
  final DateTime? resolvedAt;
  final String? notes;

  const EmergencyResolution({
    required this.emergencyId,
    required this.status,
    this.responderType,
    this.etaMinutes,
    this.resolvedAt,
    this.notes,
  });

  /// Parses from the `data.emergency` sub-object of the SSE payload.
  factory EmergencyResolution.fromJson(Map<String, dynamic> json) {
    return EmergencyResolution(
      emergencyId:   json['id'] as String,
      status:        json['status'] as String? ?? 'resolved',
      responderType: json['responder_type'] as String?,
      etaMinutes:    json['eta_minutes'] as int?,
      resolvedAt:    json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  /// Human-readable label for the responder type (French locale).
  String get responderLabel {
    switch (responderType) {
      case 'police': return '\ud83d\ude94 Police';
      case 'samu':   return '\ud83d\ude91 SAMU';
      case 'fire':   return '\ud83d\ude92 Pompiers';
      case 'other':  return '\ud83d\udc65 Autre secours';
      default:       return 'Secours en route';
    }
  }
}
