import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';

class BallotPartyItem {
  final int id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final bool isProvincialAdmitted;
  final bool isDistritalAdmitted;

  const BallotPartyItem({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.isProvincialAdmitted = true,
    this.isDistritalAdmitted = true,
  });

  factory BallotPartyItem.fromJson(Map<String, dynamic> json) {
    return BallotPartyItem(
      id: json['political_organization_id'] as int? ?? (json['id'] as int? ?? 0),
      name: json['political_organization_name']?.toString() ??
          (json['name']?.toString() ?? 'ORGANIZACIÓN POLÍTICA'),
      shortName: json['political_organization_short_name']?.toString() ??
          json['short_name']?.toString(),
      logoUrl: json['logo_url']?.toString() ?? json['local_logo_url']?.toString(),
      isProvincialAdmitted: json['is_provincial_admitted'] as bool? ?? true,
      isDistritalAdmitted: json['is_distrital_admitted'] as bool? ?? true,
    );
  }
}

class BallotTemplateResult {
  final String pollingStationCode;
  final int electoralLevelId;
  final int registeredVoters;
  final String departmentName;
  final String provinceName;
  final String districtName;
  final List<BallotPartyItem> parties;

  const BallotTemplateResult({
    required this.pollingStationCode,
    required this.electoralLevelId,
    required this.registeredVoters,
    required this.departmentName,
    required this.provinceName,
    required this.districtName,
    required this.parties,
  });
}

class BallotRepository {
  final AppDatabase db;
  final ApiClient apiClient;

  BallotRepository({required this.db, required this.apiClient});

  /// Obtiene la plantilla estructurada de la cédula para una mesa y nivel electoral.
  /// Estrategia Cache-First Resiliente:
  /// 1. Si hay red, consulta el API y actualiza el caché local SQLite en segundo plano o retorno.
  /// 2. Si no hay red o el API falla, utiliza la plantilla guardada en SQLite local (`LocalBallotTemplatesTable`).
  /// 3. Si no hay plantilla local previa, genera una plantilla basada en el catálogo local de organizaciones.
  Future<BallotTemplateResult> getBallotTemplate({
    required String pollingStationCode,
    required int electoralLevelId,
  }) async {
    final localStation = await db.getPollingStationByCode(pollingStationCode);
    final regVoters = localStation?.registeredVoters ?? 300;
    final depName = localStation?.departmentName ?? 'DEPARTAMENTO';
    final provName = localStation?.provinceName ?? 'PROVINCIA';
    final distName = localStation?.districtName ?? 'DISTRITO';

    // 1. Intentar descargar desde el API si hay conexión
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/ballot-template',
        queryParameters: {
          'polling_station_code': pollingStationCode,
          'electoral_level_id': electoralLevelId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>? ?? {};
        final listsRaw = data['lists'] as List<dynamic>? ?? [];

        // Guardar en SQLite local para acceso offline permanente
        await db.saveBallotTemplateString(
          pollingStationCode,
          electoralLevelId,
          jsonEncode(data),
        );

        final seenIds = <int>{};
        final parties = <BallotPartyItem>[];
        for (final item in listsRaw.whereType<Map<String, dynamic>>()) {
          final party = BallotPartyItem.fromJson(item);
          if (party.id > 0 && !seenIds.contains(party.id)) {
            seenIds.add(party.id);
            parties.add(party);
          }
        }

        if (parties.isNotEmpty) {
          return BallotTemplateResult(
            pollingStationCode: pollingStationCode,
            electoralLevelId: electoralLevelId,
            registeredVoters: (data['station']?['registered_voters'] as int?) ?? regVoters,
            departmentName: data['station']?['department_name']?.toString() ?? depName,
            provinceName: data['station']?['province_name']?.toString() ?? provName,
            districtName: data['station']?['district_name']?.toString() ?? distName,
            parties: parties,
          );
        }
      }
    } catch (_) {
      // Fallback a caché local si la red no está disponible
    }

    // 2. Leer desde SQLite local (Cache-First Offline)
    final localCachedJson = await db.getBallotTemplateString(pollingStationCode, electoralLevelId);
    if (localCachedJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(localCachedJson) as Map<String, dynamic>;
        final listsRaw = data['lists'] as List<dynamic>? ?? [];
        final seenIds = <int>{};
        final parties = <BallotPartyItem>[];
        for (final item in listsRaw.whereType<Map<String, dynamic>>()) {
          final party = BallotPartyItem.fromJson(item);
          if (party.id > 0 && !seenIds.contains(party.id)) {
            seenIds.add(party.id);
            parties.add(party);
          }
        }

        if (parties.isNotEmpty) {
          return BallotTemplateResult(
            pollingStationCode: pollingStationCode,
            electoralLevelId: electoralLevelId,
            registeredVoters: (data['station']?['registered_voters'] as int?) ?? regVoters,
            departmentName: data['station']?['department_name']?.toString() ?? depName,
            provinceName: data['station']?['province_name']?.toString() ?? provName,
            districtName: data['station']?['district_name']?.toString() ?? distName,
            parties: parties,
          );
        }
      } catch (_) {}
    }

    // 3. Fallback inteligente de emergencia si la mesa es 100% nueva y nunca se sincronizó
    final localOrgs = await db.getAllPoliticalOrganizations();
    final seenOrgIds = <int>{};
    final fallbackParties = <BallotPartyItem>[];
    for (final org in localOrgs) {
      if (!seenOrgIds.contains(org.id)) {
        seenOrgIds.add(org.id);
        fallbackParties.add(
          BallotPartyItem(
            id: org.id,
            name: org.name,
            shortName: org.shortName,
            logoUrl: org.logoUrl,
            isProvincialAdmitted: true,
            isDistritalAdmitted: true,
          ),
        );
      }
    }

    return BallotTemplateResult(
      pollingStationCode: pollingStationCode,
      electoralLevelId: electoralLevelId,
      registeredVoters: regVoters,
      departmentName: depName,
      provinceName: provName,
      districtName: distName,
      parties: fallbackParties,
    );
  }
}
