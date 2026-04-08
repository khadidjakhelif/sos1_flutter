class MedicalProfile {
  final String id;
  final String fullName;
  final String sosId;
  final String? avatarUrl;
  final DateTime? lastUpdated;
  final BloodType bloodType;
  final bool isUniversalDonor;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final String emergencyNotes;
  final ICEContact? iceContact;

  MedicalProfile({
    required this.id,
    required this.fullName,
    required this.sosId,
    this.avatarUrl,
    this.lastUpdated,
    required this.bloodType,
    this.isUniversalDonor = false,
    this.chronicDiseases = const [],
    this.allergies = const [],
    this.emergencyNotes = '',
    this.iceContact,
  });

  MedicalProfile copyWith({
    String? id,
    String? fullName,
    String? sosId,
    String? avatarUrl,
    DateTime? lastUpdated,
    BloodType? bloodType,
    bool? isUniversalDonor,
    List<String>? chronicDiseases,
    List<String>? allergies,
    String? emergencyNotes,
    ICEContact? iceContact,
  }) {
    return MedicalProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      sosId: sosId ?? this.sosId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      bloodType: bloodType ?? this.bloodType,
      isUniversalDonor: isUniversalDonor ?? this.isUniversalDonor,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      allergies: allergies ?? this.allergies,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      iceContact: iceContact ?? this.iceContact,
    );
  }
}

class ICEContact {
  final String name;
  final String relation;
  final String phoneNumber;

  ICEContact({
    required this.name,
    required this.relation,
    required this.phoneNumber,
  });
}

enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

extension BloodTypeExtension on BloodType {
  String get displayName {
    switch (this) {
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
    }
  }

  String get fullDisplayName {
    switch (this) {
      case BloodType.aPositive:
        return 'A+ Rh+';
      case BloodType.aNegative:
        return 'A- Rh-';
      case BloodType.bPositive:
        return 'B+ Rh+';
      case BloodType.bNegative:
        return 'B- Rh-';
      case BloodType.abPositive:
        return 'AB+ Rh+';
      case BloodType.abNegative:
        return 'AB- Rh-';
      case BloodType.oPositive:
        return 'O+ Rh+';
      case BloodType.oNegative:
        return 'O- Rh-';
    }
  }

  bool get isUniversalDonor {
    return this == BloodType.oNegative;
  }
}
