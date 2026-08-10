class UserSession {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? personeroId;
  final String token;
  final String deviceUuid;

  const UserSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.personeroId,
    required this.token,
    required this.deviceUuid,
  });

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'personero_id': personeroId,
        'token': token,
        'device_uuid': deviceUuid,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        id: _parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? (json['rol'] is Map ? (json['rol'] as Map)['name']?.toString() ?? 'PERSONERO' : 'PERSONERO'),
        personeroId: _parseNullableInt(json['personero_id']),
        token: json['token']?.toString() ?? '',
        deviceUuid: json['device_uuid']?.toString() ?? 'device-unknown',
      );

  factory UserSession.fromBackendResponse({
    required Map<String, dynamic> userData,
    required String token,
    required String deviceUuid,
  }) {
    return UserSession(
      id: _parseInt(userData['id']),
      name: userData['name']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      role: userData['role']?.toString() ??
          (userData['rol'] is Map
              ? (userData['rol'] as Map)['name']?.toString() ?? 'PERSONERO'
              : 'PERSONERO'),
      personeroId: _parseNullableInt(userData['personero_id']),
      token: token,
      deviceUuid: deviceUuid,
    );
  }
}
