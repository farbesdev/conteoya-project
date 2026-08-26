class PersoneroModel {
  final int id;
  final int? userId;
  final String dni;
  final String firstName;
  final String lastName;
  final List<String> pollingStationCodes;
  final String? phoneNumber;
  final String? email;
  final bool isActive;
  final String? politicalOrganizationName;
  final String? status;
  final String? personeroType;
  final DateTime createdAt;

  PersoneroModel({
    required this.id,
    this.userId,
    required this.dni,
    required this.firstName,
    required this.lastName,
    List<String>? pollingStationCodes,
    String? pollingStationCode,
    this.phoneNumber,
    this.email,
    this.isActive = false,
    this.politicalOrganizationName,
    this.status,
    this.personeroType,
    required this.createdAt,
  }) : pollingStationCodes = pollingStationCodes ??
            (pollingStationCode != null && pollingStationCode.isNotEmpty
                ? <String>[pollingStationCode]
                : <String>[]);

  String get pollingStationCode =>
      pollingStationCodes.isNotEmpty ? pollingStationCodes.first : '';

  String get fullName => '$firstName $lastName'.trim();

  PersoneroModel copyWith({
    int? id,
    int? userId,
    String? dni,
    String? firstName,
    String? lastName,
    List<String>? pollingStationCodes,
    String? pollingStationCode,
    String? phoneNumber,
    String? email,
    bool? isActive,
    String? politicalOrganizationName,
    String? status,
    String? personeroType,
    DateTime? createdAt,
  }) {
    return PersoneroModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dni: dni ?? this.dni,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      pollingStationCodes: pollingStationCodes ??
          (pollingStationCode != null ? [pollingStationCode] : this.pollingStationCodes),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      politicalOrganizationName: politicalOrganizationName ?? this.politicalOrganizationName,
      status: status ?? this.status,
      personeroType: personeroType ?? this.personeroType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
