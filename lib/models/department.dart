class Unit {
  final String id;
  final String departmentId;
  final String name;

  Unit({
    required this.id,
    required this.departmentId,
    required this.name,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      departmentId: json['department_id'],
      name: json['name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Department {
  final String id;
  final String companyId;
  final String name;
  final List<Unit> units;

  Department({
    required this.id,
    required this.companyId,
    required this.name,
    required this.units,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    var list = json['units'] as List? ?? [];
    List<Unit> unitsList = list.map((i) => Unit.fromJson(i)).toList();

    return Department(
      id: json['id'],
      companyId: json['company_id'],
      name: json['name'],
      units: unitsList,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
