class DepartmentUnits {
  static const Map<String, List<String>> data = {
    'Production': ['Ligne 1', 'Ligne 2', 'Salle de contrôle', 'Emballage'],
    'Maintenance': [
      'Mécanique',
      'Électrique',
      'Instrumentation',
      'Automatisme'
    ],
    'Sécurité': ['Portail principal', 'Équipe de patrouille', 'CCTV'],
    'IT': [
      'Développement',
      'Réseaux',
      'BDD',
    ],
    'Administration': ['Administration'],
    'Médical': ['Médical'],
    'Qualité': ['Qualité'],
    'Logistique': ['Logistique'],
    'Ingénierie': ['Ingénierie'],
    'HSE': ['HSE'],
  };

  static List<String> get departments => data.keys.toList();

  static List<String> unitsFor(String? department) {
    if (department == null) return [];
    return data[department] ?? [];
  }

  /// Combines selections into the flat "Dept-Unit" code sent to the backend,
  /// e.g. "Maintenance-Électrique". Single-unit departments (IT, HSE, etc.)
  /// just repeat the department name for consistency.
  static String buildCode(String department, String unit) {
    return '$department-$unit';
  }
}
