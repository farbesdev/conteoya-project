class PersoneroModel {
  final int id;
  final String dni;
  final String firstName;
  final String lastName;
  final String pollingStationCode;
  final String? phoneNumber;
  final String? email;
  final bool isActive;
  final DateTime createdAt;

  const PersoneroModel({
    required this.id,
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.pollingStationCode,
    this.phoneNumber,
    this.email,
    this.isActive = false,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  PersoneroModel copyWith({
    int? id,
    String? dni,
    String? firstName,
    String? lastName,
    String? pollingStationCode,
    String? phoneNumber,
    String? email,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PersoneroModel(
      id: id ?? this.id,
      dni: dni ?? this.dni,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
