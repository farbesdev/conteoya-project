enum ActRegistrationStatus {
  pendiente,
  registrada;

  static ActRegistrationStatus fromDbStatus(String? status) {
    if (status == null) return ActRegistrationStatus.pendiente;
    final upper = status.toUpperCase();
    if (upper == 'REGISTRADA' || upper == 'CONFIRMED' || upper == 'SYNCED' || upper == 'READY_TO_SYNC') {
      return ActRegistrationStatus.registrada;
    }
    return ActRegistrationStatus.pendiente;
  }

  bool get isRegistrada => this == ActRegistrationStatus.registrada;
  bool get isPendiente => this == ActRegistrationStatus.pendiente;

  String get label => isRegistrada ? 'Registrada' : 'Pendiente';
}

class MesaModel {
  final int id;
  final String code;
  final String locationName;
  final String districtCode;
  final String districtName;
  final String provinceName;
  final String departmentName;
  final String? odpe;
  final int registeredVoters;
  final String status;
  final String? assignedPersoneroName;
  final String? assignedPersoneroDni;
  final ActRegistrationStatus regionalStatus;
  final ActRegistrationStatus municipalStatus;

  const MesaModel({
    required this.id,
    required this.code,
    required this.locationName,
    required this.districtCode,
    required this.districtName,
    required this.provinceName,
    required this.departmentName,
    this.odpe,
    required this.registeredVoters,
    required this.status,
    this.assignedPersoneroName,
    this.assignedPersoneroDni,
    this.regionalStatus = ActRegistrationStatus.pendiente,
    this.municipalStatus = ActRegistrationStatus.pendiente,
  });

  bool get hasPersoneroAssigned => assignedPersoneroName != null && assignedPersoneroName!.isNotEmpty;

  int get registeredActsCount {
    int count = 0;
    if (regionalStatus.isRegistrada) count++;
    if (municipalStatus.isRegistrada) count++;
    return count;
  }

  bool get areAllActsRegistered => regionalStatus.isRegistrada && municipalStatus.isRegistrada;
}
