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
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        personeroId: json['personero_id'] as int?,
        token: json['token'] as String,
        deviceUuid: json['device_uuid'] as String? ?? 'device-unknown',
      );
}
