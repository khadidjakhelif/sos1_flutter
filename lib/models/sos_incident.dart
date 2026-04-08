import 'package:flutter/material.dart';

class SOSIncident {
  final String id;
  final String title;
  final IncidentType type;
  final DateTime timestamp;
  final String location;
  final String? mapImageUrl;
  final double? latitude;
  final double? longitude;
  final String status;
  final String? details;

  SOSIncident({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    required this.location,
    this.mapImageUrl,
    this.latitude,
    this.longitude,
    this.status = 'completed',
    this.details,
  });

  String get formattedDate {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

enum IncidentType {
  medical,
  security,
  fire,
  other,
}

extension IncidentTypeExtension on IncidentType {
  String get displayName {
    switch (this) {
      case IncidentType.medical:
        return 'Medical Emergency';
      case IncidentType.security:
        return 'Security Alert';
      case IncidentType.fire:
        return 'Fire Emergency';
      case IncidentType.other:
        return 'Other Emergency';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.medical:
        return Icons.medical_services;
      case IncidentType.security:
        return Icons.security;
      case IncidentType.fire:
        return Icons.local_fire_department;
      case IncidentType.other:
        return Icons.emergency;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.medical:
        return const Color(0xFFE53935);
      case IncidentType.security:
        return const Color(0xFF2196F3);
      case IncidentType.fire:
        return const Color(0xFFFF9800);
      case IncidentType.other:
        return const Color(0xFF9E9E9E);
    }
  }
}

enum IncidentTab {
  all,
  medical,
  security,
}

extension IncidentTabExtension on IncidentTab {
  String get displayName {
    switch (this) {
      case IncidentTab.all:
        return 'ALL LOGS';
      case IncidentTab.medical:
        return 'MEDICAL';
      case IncidentTab.security:
        return 'SECURITY';
    }
  }
}
