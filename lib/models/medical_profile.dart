import 'package:hive/hive.dart';

part 'medical_profile.g.dart';

/// Type IDs — never change these once set
// MedicalProfile → 0
// ICEContact     → 1
// BloodType      → 2

@HiveType(typeId: 0)
class MedicalProfile {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String fullName;
  @HiveField(2)
  final String sosId;
  @HiveField(3)
  final String? avatarUrl;
  @HiveField(4)
  final DateTime? lastUpdated;
  @HiveField(5)
  final BloodType bloodType;
  @HiveField(6)
  final bool isUniversalDonor;
  @HiveField(7)
  final List<String> chronicDiseases;
  @HiveField(8)
  final List<String> allergies;
  @HiveField(9)
  final String emergencyNotes;
  @HiveField(10)
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

  factory MedicalProfile.fromJson(Map<String, dynamic> json,
      {String fullName = ''}) {
    return MedicalProfile(
      id: json['id'] ?? '',
      fullName: fullName,
      sosId: json['user_id'] ?? '',
      avatarUrl: null, // not part of this endpoint
      lastUpdated: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      bloodType: BloodTypeExtension.fromString(json['blood_type']),
      isUniversalDonor: json['is_universal_donor'] ?? false,
      chronicDiseases: List<String>.from(json['chronic_diseases'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      emergencyNotes: json['emergency_notes'] ?? '',
      iceContact: (json['ice_contact_name'] != null &&
              (json['ice_contact_name'] as String).isNotEmpty)
          ? ICEContact(
              name: json['ice_contact_name'] ?? '',
              relation: json['ice_contact_relation'] ?? '',
              phoneNumber: json['ice_contact_phone'] ?? '',
            )
          : null,
    );
  }
}

@HiveType(typeId: 1)
class ICEContact {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String relation;
  @HiveField(2)
  final String phoneNumber;

  ICEContact({
    required this.name,
    required this.relation,
    required this.phoneNumber,
  });

  ICEContact copyWith({String? name, String? relation, String? phoneNumber}) {
    return ICEContact(
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

@HiveType(typeId: 2)
enum BloodType {
  @HiveField(0)
  aPositive,
  @HiveField(1)
  aNegative,
  @HiveField(2)
  bPositive,
  @HiveField(3)
  bNegative,
  @HiveField(4)
  abPositive,
  @HiveField(5)
  abNegative,
  @HiveField(6)
  oPositive,
  @HiveField(7)
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

  static BloodType fromString(String? value) {
    switch (value) {
      case 'A+':
        return BloodType.aPositive;
      case 'A-':
        return BloodType.aNegative;
      case 'B+':
        return BloodType.bPositive;
      case 'B-':
        return BloodType.bNegative;
      case 'AB+':
        return BloodType.abPositive;
      case 'AB-':
        return BloodType.abNegative;
      case 'O+':
        return BloodType.oPositive;
      case 'O-':
        return BloodType.oNegative;
      default:
        return BloodType.oPositive;
    }
  }

  bool get isUniversalDonor => this == BloodType.oNegative;
}
