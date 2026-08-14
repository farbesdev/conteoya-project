import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/speed_dial_fab.dart';
import '../../mesas/domain/mesa_model.dart';
import '../../mesas/presentation/add_mesa_modal.dart';
import 'select_act_type_modal.dart';

class AdminActasScreen extends ConsumerStatefulWidget {
  const AdminActasScreen({super.key});

  @override
  ConsumerState<AdminActasScreen> createState() => _AdminActasScreenState();
}

class _AdminActasScreenState extends ConsumerState<AdminActasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMesaPickerForActa(List<MesaModel> mesas) {
    if (mesas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('No hay mesas registradas. Agregue una mesa primero.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Seleccione una Mesa para Registrar Acta:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mesas.length,
                itemBuilder: (context, index) {
                  final m = mesas[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 20),
                    ),
                    title: Text(
                      'Mesa ${m.code}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${m.locationName} • ${m.districtName}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.pop(ctx);
                      SelectActTypeModal.show(
                        context,
                        pollingStationCode: m.code,
                        mesaLocationName: m.locationName,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mesasAsync = ref.watch(mesasStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Barra de Búsqueda
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por código de mesa, local o distrito...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),

          // Listado de Mesas y Estado de Actas
          Expanded(
            child: mesasAsync.when(
              data: (mesas) {
                final filtered = mesas.where((m) {
                  if (_searchQuery.isEmpty) return true;
                  return m.code.toLowerCase().contains(_searchQuery) ||
                      m.locationName.toLowerCase().contains(_searchQuery) ||
                      m.districtName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.ballot_outlined,
                              color: AppColors.textMuted,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron mesas para "$_searchQuery"'
                                : 'No hay mesas registradas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presione el botón (+) para agregar una mesa o acta.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final mesa = filtered[index];
                    return _buildMesaCard(context, mesa);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => Center(
                child: Text('Error al cargar mesas: $e', style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: mesasAsync.maybeWhen(
        data: (mesas) => SpeedDialFab(
          mainIcon: Icons.add,
          options: [
            SpeedDialOption(
              icon: Icons.description_rounded,
              label: '+ Acta',
              color: AppColors.accent,
              onTap: () => _showMesaPickerForActa(mesas),
            ),
            SpeedDialOption(
              icon: Icons.how_to_vote_rounded,
              label: '+ Mesa',
              color: AppColors.info,
              onTap: () => AddMesaModal.show(context),
            ),
          ],
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildMesaCard(BuildContext context, MesaModel mesa) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Mesa + Electores
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mesa ${mesa.code}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${mesa.registeredVoters} electores',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Local y Distrito
          Text(
            mesa.locationName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Text(
            mesa.districtName,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),

          // Personero Asignado
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                mesa.hasPersoneroAssigned
                    ? 'Personero: ${mesa.assignedPersoneroName}'
                    : 'Sin personero asignado',
                style: TextStyle(
                  color: mesa.hasPersoneroAssigned ? AppColors.textSecondary : AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Estado de Actas (Regional / Municipal)
          Row(
            children: [
              Expanded(
                child: _buildActStatusBadge(
                  title: 'Regional',
                  status: mesa.regionalStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActStatusBadge(
                  title: 'Municipal',
                  status: mesa.municipalStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Botón de Acción [ Ver / Registrar actas ]
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit_document, size: 18),
              label: const Text(
                'Ver / Registrar actas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                SelectActTypeModal.show(
                  context,
                  pollingStationCode: mesa.code,
                  mesaLocationName: mesa.locationName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActStatusBadge({
    required String title,
    required ActRegistrationStatus status,
  }) {
    final isReg = status.isRegistrada;
    final color = isReg ? AppColors.success : AppColors.warning;
    final icon = isReg ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    status.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
