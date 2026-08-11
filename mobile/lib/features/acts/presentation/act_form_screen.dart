import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hash_utils.dart';
import '../domain/act_validator.dart';
import '../domain/electoral_level.dart';
import 'party_logo_widget.dart';
import '../../ocr_ai/presentation/ocr_preview_modal.dart';

class ActFormScreen extends ConsumerStatefulWidget {
  final String pollingStationCode;
  final int electionId;
  final int electoralLevelId;

  const ActFormScreen({
    super.key,
    required this.pollingStationCode,
    this.electionId = 1,
    this.electoralLevelId = 1,
  });

  @override
  ConsumerState<ActFormScreen> createState() => _ActFormScreenState();
}

class _ActFormScreenState extends ConsumerState<ActFormScreen> {
  final String _clientActUuid = const Uuid().v4();
  late int _selectedLevelId;

  // Controllers de Totales
  final TextEditingController _registeredVotersController = TextEditingController(text: '300');
  final TextEditingController _votersWhoVotedController = TextEditingController(text: '280');
  final TextEditingController _totalVotesController = TextEditingController(text: '280');
  final TextEditingController _blankVotesController = TextEditingController(text: '10');
  final TextEditingController _nullVotesController = TextEditingController(text: '5');
  final TextEditingController _challengedVotesController = TextEditingController(text: '0');

  // Listas electorales oficiales JEE de Organizaciones Políticas con sus logos
  final List<Map<String, Object?>> _parties = [
    {
      'id': 4,
      'name': 'ACCIÓN POPULAR',
      'shortName': 'AP',
      'logoUrl': 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/4.png',
      'votesController': TextEditingController(text: '85'),
      'source': 'MANUAL',
      'confidence': null,
    },
    {
      'id': 14,
      'name': 'PARTIDO DEMOCRÁTICO SOMOS PERÚ',
      'shortName': 'SOMOS PERU',
      'logoUrl': 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/14.png',
      'votesController': TextEditingController(text: '70'),
      'source': 'MANUAL',
      'confidence': null,
    },
    {
      'id': 1257,
      'name': 'ALIANZA PARA EL PROGRESO',
      'shortName': 'APP',
      'logoUrl': 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1257.png',
      'votesController': TextEditingController(text: '55'),
      'source': 'MANUAL',
      'confidence': null,
    },
    {
      'id': 1264,
      'name': 'JUNTOS POR EL PERÚ',
      'shortName': 'JP',
      'logoUrl': 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1264.png',
      'votesController': TextEditingController(text: '30'),
      'source': 'MANUAL',
      'confidence': null,
    },
    {
      'id': 1366,
      'name': 'FUERZA POPULAR',
      'shortName': 'FP',
      'logoUrl': 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1366.png',
      'votesController': TextEditingController(text: '25'),
      'source': 'MANUAL',
      'confidence': null,
    },
    {
      'id': 2173,
      'name': 'AVANZA PAIS',
      'shortName': 'AVANZA PAIS',
      'logoUrl': 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2173.png',
      'votesController': TextEditingController(text: '15'),
      'source': 'MANUAL',
      'confidence': null,
    },
  ];

  File? _capturedPhoto;
  String? _photoSha256;
  bool _isSaving = false;

  ActValidationResult _validationResult = const ActValidationResult(isValid: true, warnings: []);

  @override
  void initState() {
    super.initState();
    _selectedLevelId = widget.electoralLevelId;
    _recalculateValidation();
  }

  void _recalculateValidation() {
    final registered = int.tryParse(_registeredVotersController.text) ?? 0;
    final voters = int.tryParse(_votersWhoVotedController.text) ?? 0;
    final total = int.tryParse(_totalVotesController.text) ?? 0;
    final blank = int.tryParse(_blankVotesController.text) ?? 0;
    final nullVotes = int.tryParse(_nullVotesController.text) ?? 0;
    final challenged = int.tryParse(_challengedVotesController.text) ?? 0;

    final candidateVotes = _parties
        .map((p) => int.tryParse((p['votesController'] as TextEditingController).text) ?? 0)
        .toList();

    setState(() {
      _validationResult = ActValidator.validate(
        registeredVoters: registered,
        votersWhoVoted: voters,
        totalVotes: total,
        blankVotes: blank,
        nullVotes: nullVotes,
        challengedVotes: challenged,
        candidateVotes: candidateVotes,
      );
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (image != null) {
      final file = File(image.path);
      final hash = await HashUtils.calculateFileSha256(file);
      setState(() {
        _capturedPhoto = file;
        _photoSha256 = hash;
      });
    }
  }

  void _triggerOcrAssist() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrPreviewModal(
        extractionData: const {
          'confidence_map': [
            {'field': 'electores_habiles', 'confidence': 0.98},
            {'field': 'votantes', 'confidence': 0.95},
            {'field': 'total_votos', 'confidence': 0.96},
            {'field': 'votos_blancos', 'confidence': 0.90},
            {'field': 'votos_nulos', 'confidence': 0.88},
            {'field': 'partido_1_votos', 'confidence': 0.94},
            {'field': 'partido_2_votos', 'confidence': 0.82},
          ],
          'results': [
            {'party_id': 1, 'votes': 85},
            {'party_id': 2, 'votes': 70},
          ]
        },
        onApply: () {
          setState(() {
            _registeredVotersController.text = '300';
            _votersWhoVotedController.text = '280';
            _totalVotesController.text = '280';
            _blankVotesController.text = '10';
            _nullVotesController.text = '5';

            (_parties[0]['votesController'] as TextEditingController).text = '85';
            _parties[0]['source'] = 'OCR';
            _parties[0]['confidence'] = 0.94;

            (_parties[1]['votesController'] as TextEditingController).text = '70';
            _parties[1]['source'] = 'OCR';
            _parties[1]['confidence'] = 0.82;
          });
          _recalculateValidation();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Valores OCR cargados. Por favor confirme antes de guardar.'),
              backgroundColor: AppColors.info,
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAct({required bool isConfirmation}) async {
    setState(() => _isSaving = true);
    final db = ref.read(appDatabaseProvider);
    final clientOpId = const Uuid().v4();

    final registered = int.tryParse(_registeredVotersController.text) ?? 0;
    final voters = int.tryParse(_votersWhoVotedController.text) ?? 0;
    final total = int.tryParse(_totalVotesController.text) ?? 0;
    final blank = int.tryParse(_blankVotesController.text) ?? 0;
    final nullVotes = int.tryParse(_nullVotesController.text) ?? 0;
    final challenged = int.tryParse(_challengedVotesController.text) ?? 0;

    final status = isConfirmation ? 'READY_TO_SYNC' : 'DRAFT';

    // 1. Guardar en SQLite local (Drift)
    await db.saveCompleteAct(
      act: LocalActsTableCompanion(
        clientActUuid: drift.Value(_clientActUuid),
        electionId: drift.Value(widget.electionId),
        electoralLevelId: drift.Value(_selectedLevelId),
        pollingStationCode: drift.Value(widget.pollingStationCode),
        status: drift.Value(status),
        capturedAt: drift.Value(DateTime.now()),
      ),
      totals: LocalActTotalsTableCompanion(
        clientActUuid: drift.Value(_clientActUuid),
        registeredVoters: drift.Value(registered),
        votersWhoVoted: drift.Value(voters),
        totalVotes: drift.Value(total),
        blankVotes: drift.Value(blank),
        nullVotes: drift.Value(nullVotes),
        challengedVotes: drift.Value(challenged),
        isValidTotal: drift.Value(_validationResult.isValid),
      ),
      results: _parties.map((p) {
        final votes = int.tryParse((p['votesController'] as TextEditingController).text) ?? 0;
        return LocalActResultsTableCompanion(
          clientActUuid: drift.Value(_clientActUuid),
          politicalOrganizationId: drift.Value(p['id'] as int),
          politicalOrganizationName: drift.Value(p['name'] as String),
          votes: drift.Value(votes),
          source: drift.Value(p['source'] as String? ?? 'MANUAL'),
          confidence: drift.Value(p['confidence'] as double?),
        );
      }).toList(),
    );

    // 2. Si hay fotografía, registrar evidencia local
    if (_capturedPhoto != null && _photoSha256 != null) {
      await db.into(db.localActEvidenceTable).insert(
        LocalActEvidenceTableCompanion(
          clientActUuid: drift.Value(_clientActUuid),
          localFilePath: drift.Value(_capturedPhoto!.path),
          sha256Hash: drift.Value(_photoSha256!),
          fileSizeBytes: drift.Value(_capturedPhoto!.lengthSync()),
          isUploaded: const drift.Value(false),
          capturedAt: drift.Value(DateTime.now()),
        ),
      );
    }

    // 3. Si se confirma, encolar operación de sincronización
    if (isConfirmation) {
      final payload = {
        'polling_station_code': widget.pollingStationCode,
        'election_id': widget.electionId,
        'electoral_level_id': _selectedLevelId,
        'status': 'CONFIRMED',
        'totals': {
          'registered_voters': registered,
          'voters_who_voted': voters,
          'total_votes': total,
          'blank_votes': blank,
          'null_votes': nullVotes,
          'challenged_votes': challenged,
        },
        'results': _parties.map((p) {
          final votes = int.tryParse((p['votesController'] as TextEditingController).text) ?? 0;
          return {
            'political_organization_id': p['id'],
            'votes': votes,
            'source': p['source'],
            'confidence': p['confidence'],
          };
        }).toList(),
      };

      await db.enqueueSyncOperation(
        LocalSyncOperationsTableCompanion.insert(
          clientOperationId: clientOpId,
          entityType: 'acts',
          entityId: _clientActUuid,
          payloadJson: jsonEncode(payload),
          checksum: drift.Value(_photoSha256 ?? ''),
          status: const drift.Value('PENDING'),
        ),
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConfirmation
                ? 'Acta confirmada y encolada para sincronización.'
                : 'Borrador guardado localmente.',
          ),
          backgroundColor: isConfirmation ? AppColors.success : AppColors.info,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = getElectoralLevelById(_selectedLevelId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Registro de Acta — Mesa ${widget.pollingStationCode}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.info),
            tooltip: 'Asistente OCR / IA',
            onPressed: _triggerOcrAssist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector del Tipo de Acta / Nivel Electoral (Gobernador, Provincial, Distrital)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentLevel.color.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de Acta Electoral:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kElectoralLevels.map((level) {
                        final isSelected = level.id == _selectedLevelId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              level.icon,
                              size: 16,
                              color: isSelected ? Colors.white : level.color,
                            ),
                            label: Text(level.shortTitle),
                            selected: isSelected,
                            selectedColor: level.color,
                            backgroundColor: AppColors.surfaceElevated,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedLevelId = level.id;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Banner de Advertencias de Validación en Tiempo Real
            if (!_validationResult.isValid)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Advertencias de Consistencia Numérica',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._validationResult.warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${w.message}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Sección 1: Totales del Acta
            _buildSectionCard(
              title: 'Totales del Acta (${currentLevel.shortTitle})',
              icon: Icons.calculate_outlined,
              child: Column(
                children: [
                  _buildNumberField('Electores Hábiles', _registeredVotersController),
                  _buildNumberField('Ciudadanos que Votaron', _votersWhoVotedController),
                  _buildNumberField('Total de Votos Emitidos', _totalVotesController),
                  const Divider(color: AppColors.border, height: 24),
                  _buildNumberField('Votos en Blanco', _blankVotesController),
                  _buildNumberField('Votos Nulos', _nullVotesController),
                  _buildNumberField('Votos Impugnados', _challengedVotesController),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sección 2: Votos por Organización Política con Logos Oficiales
            _buildSectionCard(
              title: 'Votos por Organización Política',
              icon: Icons.how_to_vote_outlined,
              child: Column(
                children: _parties.map((party) {
                  final name = party['name'] as String;
                  final shortName = party['shortName'] as String?;
                  final logoUrl = party['logoUrl'] as String?;
                  final controller = party['votesController'] as TextEditingController;
                  final source = party['source'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Logo oficial de la Organización Política
                        PartyLogoWidget(
                          logoUrl: logoUrl,
                          name: name,
                          shortName: shortName,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (source != 'MANUAL')
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Fuente: $source',
                                    style: const TextStyle(color: AppColors.info, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            onChanged: (_) => _recalculateValidation(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Sección 3: Evidencia Fotográfica
            _buildSectionCard(
              title: 'Fotografía del Acta',
              icon: Icons.camera_alt_outlined,
              child: Column(
                children: [
                  if (_capturedPhoto != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_capturedPhoto!, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SHA-256: ${_photoSha256?.substring(0, 16)}...',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_capturedPhoto == null ? 'Capturar Foto del Acta' : 'Tomar Otra Foto'),
                    onPressed: _takePhoto,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones de Acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _isSaving ? null : () => _saveAct(isConfirmation: false),
                    child: const Text('Guardar Borrador'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _isSaving ? null : () => _saveAct(isConfirmation: true),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirmar y Sincronizar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (_) => _recalculateValidation(),
            ),
          ),
        ],
      ),
    );
  }
}
