class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? relation;
  final String? avatarUrl;
  final bool smsAlertEnabled;
  final bool autoCallEnabled;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relation,
    this.avatarUrl,
    this.smsAlertEnabled = true,
    this.autoCallEnabled = false,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relation,
    String? avatarUrl,
    bool? smsAlertEnabled,
    bool? autoCallEnabled,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relation: relation ?? this.relation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      smsAlertEnabled: smsAlertEnabled ?? this.smsAlertEnabled,
      autoCallEnabled: autoCallEnabled ?? this.autoCallEnabled,
    );
  }
}

class PublicService {
  final String id;
  final String name;
  final String shortNumber;
  final String fullNumber;
  final ServiceType type;
  final String iconAsset;

  PublicService({
    required this.id,
    required this.name,
    required this.shortNumber,
    required this.fullNumber,
    required this.type,
    required this.iconAsset,
  });
}

enum ServiceType {
  police,
  civilProtection,
  medical,
  fire,
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.police:
        return 'Police';
      case ServiceType.civilProtection:
        return 'Protection Civile';
      case ServiceType.medical:
        return 'SAMU';
      case ServiceType.fire:
        return 'Pompiers';
    }
  }

  String get iconName {
    switch (this) {
      case ServiceType.police:
        return 'shield';
      case ServiceType.civilProtection:
        return 'fire';
      case ServiceType.medical:
        return 'medical';
      case ServiceType.fire:
        return 'fire_department';
    }
  }
}
