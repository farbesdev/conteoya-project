import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _hasMore = true;

  // Lista en memoria para paginación y búsqueda remota
  List<MesaModel>? _remoteMesas;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final repo = ref.read(mesasRepositoryProvider);
    final nextPage = _currentPage + 1;
    final result = await repo.fetchRemotePollingStations(
      search: _searchQuery,
      page: nextPage,
      perPage: 10,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.items.isNotEmpty) {
          _currentPage = nextPage;
          final current = _remoteMesas ?? ref.read(mesasStreamProvider).value ?? [];
          final existingCodes = current.map((m) => m.code).toSet();
          final newUniqueItems = result.items.where((m) => !existingCodes.contains(m.code)).toList();
          _remoteMesas = [...current, ...newUniqueItems];
        }
        _hasMore = result.hasMore;
      });
    }
  }

  void _onSearchChanged(String val) {
    final query = val.trim().toLowerCase();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      // Al limpiar la búsqueda, vuelve al estado inicial local de inmediato
      setState(() {
        _searchQuery = '';
        _remoteMesas = null;
        _isSearching = false;
        _currentPage = 1;
        _hasMore = true;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _hasMore = true;
    });

    if (query.length >= 2) {
      setState(() => _isSearching = true);
      _debounceTimer = Timer(const Duration(milliseconds: 450), () {
        _performSearch(query);
      });
    } else {
      setState(() {
        _isSearching = false;
        _remoteMesas = null;
      });
    }
  }

  void _onSearchSubmitted(String val) {
    final query = val.trim().toLowerCase();
    _debounceTimer?.cancel();
    FocusScope.of(context).unfocus();

    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _remoteMesas = null;
        _isSearching = false;
        _currentPage = 1;
        _hasMore = true;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _hasMore = true;
      _isSearching = true;
    });

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    final repo = ref.read(mesasRepositoryProvider);
    final result = await repo.fetchRemotePollingStations(
      search: query,
      page: 1,
      perPage: 10,
    );
    if (mounted && _searchQuery == query) {
      setState(() {
        _remoteMesas = result.items;
        _hasMore = result.hasMore;
        _isSearching = false;
      });
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Barra de Búsqueda
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: subtleBorder, width: 0.5)),
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Buscar por código de mesa, local o distrito...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withAlpha(128)),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      )
                    : _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withAlpha(128), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),

          // Listado de Mesas con Scroll Infinito
          Expanded(
            child: mesasAsync.when(
              data: (localMesas) {
                // Si tenemos resultados remotos, los mostramos; si aún no o falló, filtramos localmente
                List<MesaModel> filtered;
                if (_remoteMesas != null) {
                  filtered = _remoteMesas!;
                } else {
                  filtered = localMesas.where((m) {
                    if (_searchQuery.isEmpty) return true;
                    return m.code.toLowerCase().contains(_searchQuery) ||
                        m.locationName.toLowerCase().contains(_searchQuery) ||
                        m.districtName.toLowerCase().contains(_searchQuery) ||
                        (m.provinceName?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (m.departmentName?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();
                }

                if (filtered.isEmpty && !_isLoadingMore) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.ballot_outlined,
                              color: theme.colorScheme.onSurface.withAlpha(128),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron mesas para "$_searchQuery"'
                                : 'No hay mesas registradas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(178),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presione el botón (+) para agregar una mesa o acta.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                        ),
                      );
                    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final textMuted = theme.colorScheme.onSurface.withAlpha(128);
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

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
                  color: AppColors.accent.withValues(alpha: 0.12),
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
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Local y Distrito
          Text(
            mesa.locationName,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Text(
            mesa.districtName,
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),

          // Personero Asignado
          Row(
            children: [
              Icon(Icons.person_outline_rounded, color: textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                mesa.hasPersoneroAssigned
                    ? 'Personero: ${mesa.assignedPersoneroName}'
                    : 'Sin personero asignado',
                style: TextStyle(
                  color: mesa.hasPersoneroAssigned ? textSecondary : AppColors.warningOf(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: subtleBorder, height: 1),
          const SizedBox(height: 12),

          // Estado de Actas (Regional / Municipal)
          Row(
            children: [
              Expanded(
                child: _buildActStatusBadge(
                  context: context,
                  title: 'Regional',
                  status: mesa.regionalStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActStatusBadge(
                  context: context,
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
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 1),
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
    required BuildContext context,
    required String title,
    required ActRegistrationStatus status,
  }) {
    final isReg = status.isRegistrada;
    final color = isReg ? AppColors.successOf(context) : AppColors.warningOf(context);
    final icon = isReg ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
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
