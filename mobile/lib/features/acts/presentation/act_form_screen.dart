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

  // Controllers de Totales
  final TextEditingController _registeredVotersController = TextEditingController(text: '300');
  final TextEditingController _votersWhoVotedController = TextEditingController(text: '280');
  final TextEditingController _totalVotesController = TextEditingController(text: '280');
  final TextEditingController _blankVotesController = TextEditingController(text: '10');
  final TextEditingController _nullVotesController = TextEditingController(text: '5');
  final TextEditingController _challengedVotesController = TextEditingController(text: '0');

  // Listas electorales simuladas / locales
  final List<Map<String, Object?>> _parties = [
    {
      'id': 1,
      'name': 'PARTIDO DEMÓCRATA',
      'votesController': TextEditingController(text: '145'),
      'source': 'MANUAL',
      'confidence': null,
    },
    {
      'id': 2,
      'name': 'MOVIMIENTO REGIONAL FUTURO',
      'votesController': TextEditingController(text: '120'),
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
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) {
      final file = File(photo.path);
      final sha256 = await HashUtils.calculateFileSha256(file);
      setState(() {
        _capturedPhoto = file;
        _photoSha256 = sha256;
      });
    }
  }

  Future<void> _triggerOcrAssist() async {
    // Simulación de respuesta OCR estructurada para Human-in-the-Loop
    final mockExtraction = {
      'polling_station_code': widget.pollingStationCode,
      'confidence_map': [
        {'field': 'Mesa de Votación', 'value': widget.pollingStationCode, 'confidence': 0.99},
        {'field': 'Electores Hábiles', 'value': 300, 'confidence': 0.98},
        {'field': 'Ciudadanos que Votaron', 'value': 280, 'confidence': 0.94},
        {'field': 'Votos en Blanco', 'value': 10, 'confidence': 0.92},
        {'field': 'Votos Nulos', 'value': 5, 'confidence': 0.88},
        {'field': 'Votos Impugnados', 'value': 0, 'confidence': 0.72}, // Baja confianza
        {'field': 'Total de Votos Emitidos', 'value': 280, 'confidence': 0.96},
      ],
      'results': [
        {'political_organization_id': 1, 'votes': 145, 'confidence': 0.96},
        {'political_organization_id': 2, 'votes': 120, 'confidence': 0.92},
      ],
    };

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrPreviewModal(
        extractionData: mockExtraction,
        onApply: () {
          setState(() {
            _registeredVotersController.text = '300';
            _votersWhoVotedController.text = '280';
            _blankVotesController.text = '10';
            _nullVotesController.text = '5';
            _challengedVotesController.text = '0';
            _totalVotesController.text = '280';

            (_parties[0]['votesController'] as TextEditingController).text = '145';
            _parties[0]['source'] = 'OCR';
            _parties[0]['confidence'] = 0.96;

            (_parties[1]['votesController'] as TextEditingController).text = '120';
            _parties[1]['source'] = 'OCR';
            _parties[1]['confidence'] = 0.92;
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

    final resultsList = _parties.map((p) {
      final votes = int.tryParse((p['votesController'] as TextEditingController).text) ?? 0;
      return {
        'political_organization_id': p['id'],
        'votes': votes,
        'source': p['source'],
        'confidence': p['confidence'],
      };
    }).toList();

    final status = isConfirmation ? 'READY_TO_SYNC' : 'DRAFT';

    // 1. Guardar en SQLite local (Drift)
    await db.saveCompleteAct(
      act: LocalActsTableCompanion(
        clientActUuid: drift.Value(_clientActUuid),
        electionId: drift.Value(widget.electionId),
        electoralLevelId: drift.Value(widget.electoralLevelId),
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
        'electoral_level_id': widget.electoralLevelId,
        'status': 'CONFIRMED',
        'totals': {
          'registered_voters': registered,
          'voters_who_voted': voters,
          'total_votes': total,
          'blank_votes': blank,
          'null_votes': nullVotes,
          'challenged_votes': challenged,
        },
        'results': resultsList,
      };

      await db.enqueueSyncOperation(
        LocalSyncOperationsTableCompanion(
          clientOperationId: drift.Value(clientOpId),
          entityType: const drift.Value('acts'),
          entityId: drift.Value(_clientActUuid),
          operation: const drift.Value('CREATE'),
          payloadJson: drift.Value(jsonEncode(payload)),
          checksum: drift.Value(HashUtils.calculateStringSha256(jsonEncode(payload))),
          status: const drift.Value('PENDING'),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      // Disparar sincronización si hay red
      ref.read(syncEngineProvider).syncPendingOperations();
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isConfirmation
            ? 'Acta confirmada y encolada para sincronización.'
            : 'Borrador guardado localmente en SQLite.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Mesa ${widget.pollingStationCode}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              title: 'Totales del Acta',
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

            // Sección 2: Votos por Lista Electoral
            _buildSectionCard(
              title: 'Votos por Organización Política',
              icon: Icons.how_to_vote_outlined,
              child: Column(
                children: _parties.map((party) {
                  final name = party['name'] as String;
                  final controller = party['votesController'] as TextEditingController;
                  final source = party['source'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
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
              title: 'Fotografía del Acta (Evidencia)',
              icon: Icons.camera_alt_outlined,
              child: Column(
                children: [
                  if (_capturedPhoto != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_capturedPhoto!, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SHA-256: ${_photoSha256?.substring(0, 16)}...',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.photo_camera),
                      label: Text(_capturedPhoto != null ? 'Tomar Otra Fotografía' : 'Capturar Fotografía del Acta'),
                      onPressed: _takePhoto,
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : () => _saveAct(isConfirmation: true),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Confirmar Acta',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
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
