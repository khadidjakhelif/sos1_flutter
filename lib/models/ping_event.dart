/// Data model for a PING_SENT SSE event received from the backend.
class PingEvent {
  final String emergencyId;
  final DateTime pingSentAt;
  final int windowSeconds;

  const PingEvent({
    required this.emergencyId,
    required this.pingSentAt,
    required this.windowSeconds,
  });

  factory PingEvent.fromJson(Map<String, dynamic> json) {
    return PingEvent(
      emergencyId:   json['emergency_id'] as String,
      pingSentAt:    DateTime.parse(json['ping_sent_at'] as String),
      windowSeconds: (json['window_seconds'] as num?)?.toInt() ?? 60,
    );
  }
}
