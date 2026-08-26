import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/personero_model.dart';
import 'delete_personero_dialog.dart';
import 'personero_form_modal.dart';

class PersonerosScreen extends ConsumerStatefulWidget {
  const PersonerosScreen({super.key});

  @override
  ConsumerState<PersonerosScreen> createState() => _PersonerosScreenState();
}

class _PersonerosScreenState extends ConsumerState<PersonerosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool? _selectedFilter; // null = Todos, true = Activos, false = Inactivos

  // Lista en memoria para paginación y búsqueda remota
  List<PersoneroModel>? _remotePersoneros;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(personerosRepositoryProvider);
    final result = await repo.fetchRemotePersoneros(
      search: _searchQuery,
      page: 1,
      perPage: 15,
      isActive: _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentPage = 1;
        _remotePersoneros = result.items;
        _hasMore = result.hasMore;
        _totalCount = result.total;
      });
    }
  }

  Future<void> _refresh() async {
    final repo = ref.read(personerosRepositoryProvider);
    final result = await repo.fetchRemotePersoneros(
      search: _searchQuery,
      page: 1,
      perPage: 15,
      isActive: _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _currentPage = 1;
        _remotePersoneros = result.items;
        _hasMore = result.hasMore;
        _totalCount = result.total;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final repo = ref.read(personerosRepositoryProvider);
    final nextPage = _currentPage + 1;
    final result = await repo.fetchRemotePersoneros(
      search: _searchQuery,
      page: nextPage,
      perPage: 15,
      isActive: _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.items.isNotEmpty) {
          _currentPage = nextPage;
          final current = _remotePersoneros ?? [];
          final existingIds = current.map((p) => p.id).toSet();
          final newUnique = result.items.where((p) => !existingIds.contains(p.id)).toList();
          _remotePersoneros = [...current, ...newUnique];
        }
        _hasMore = result.hasMore;
        _totalCount = result.total;
      });
    }
  }

  Future<void> _onSearchChanged(String val) async {
    final query = val.trim();
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _hasMore = true;
    });

    final repo = ref.read(personerosRepositoryProvider);
    final result = await repo.fetchRemotePersoneros(
      search: query,
      page: 1,
      perPage: 15,
      isActive: _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _remotePersoneros = result.items;
        _hasMore = result.hasMore;
        _totalCount = result.total;
      });
    }
  }  @override
  Widget build(BuildContext context) {
    final personerosAsync = ref.watch(personerosStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header / Barra de Búsqueda
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: subtleBorder, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  onSubmitted: _onSearchChanged,
                  onChanged: (val) {
                    if (val.isEmpty || val.length >= 2) {
                      _onSearchChanged(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por DNI, nombres, apellidos o mesa...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withAlpha(128)),
                    suffixIcon: _searchQuery.isNotEmpty
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
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Todos',
                        selected: _selectedFilter == null,
                        onSelected: (_) => _onFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Activos',
                        selected: _selectedFilter == true,
                        onSelected: (_) => _onFilterChanged(true),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Inactivos',
                        selected: _selectedFilter == false,
                        onSelected: (_) => _onFilterChanged(false),
                      ),
                    ],
                  ),
                ),
                if (_totalCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: $_totalCount personeros registrados',
                        style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 1.5),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Listado de Personeros con RefreshIndicator y Scroll Infinito
          Expanded(
            child: _isLoading && (_remotePersoneros == null || _remotePersoneros!.isEmpty)
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.accent,
                    child: _buildPersonerosList(personerosAsync),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_personero',
        backgroundColor: AppColors.accent,
        elevation: 2,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Agregar Personero',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await PersoneroFormModal.show(context);
          _refresh();
        },
      ),
    );
  }

  Widget _buildPersonerosList(AsyncValue<List<PersoneroModel>> personerosAsync) {
    // Si tenemos datos remotos de la API, usarlos con paginación
    if (_remotePersoneros != null) {
      if (_remotePersoneros!.isEmpty) {
        return _buildEmptyView();
      }

      return ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _remotePersoneros!.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _remotePersoneros!.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                ),
              ),
            );
          }
          final personero = _remotePersoneros![index];
          return _buildPersoneroCard(context, personero, index: index);
        },
      );
    }

    // Fallback Offline a Drift SQLite local
    return personerosAsync.when(
      data: (personeros) {
        final queryTerms = _searchQuery.toLowerCase().trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
        final filtered = personeros.where((p) {
          if (_selectedFilter != null && p.isActive != _selectedFilter) {
            return false;
          }
          if (queryTerms.isEmpty) return true;
          final searchTarget = '${p.dni} ${p.fullName} ${p.firstName} ${p.lastName} ${p.pollingStationCode} ${p.politicalOrganizationName ?? ''} ${p.email ?? ''}'.toLowerCase();
          return queryTerms.every((term) => searchTarget.contains(term));
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyView();
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final personero = filtered[index];
            return _buildPersoneroCard(context, personero);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(
        child: Text('Error al cargar personeros: $e', style: const TextStyle(color: AppColors.danger)),
      ),
    );
  }

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                Icons.people_outline_rounded,
                color: theme.colorScheme.onSurface.withAlpha(128),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron personeros para "$_searchQuery"'
                  : 'No hay personeros registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(178),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deslice hacia abajo para actualizar o presione (+) para registrar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersoneroCard(BuildContext context, PersoneroModel personero, {int? index}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final textMuted = theme.colorScheme.onSurface.withAlpha(128);
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);
    final warningColor = AppColors.warningOf(context);
    final successColor = AppColors.successOf(context);
    final dangerColor = AppColors.dangerOf(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: Avatar + Nombre + Mesa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personero.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined, color: textMuted, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'DNI: ${personero.dni}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (personero.politicalOrganizationName != null && personero.politicalOrganizationName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: textMuted, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              personero.politicalOrganizationName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.accentOf(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (personero.pollingStationCodes.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    runSpacing: 4,
                    children: personero.pollingStationCodes.map((code) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.how_to_vote_rounded, color: AppColors.info, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              'Mesa $code',
                              style: const TextStyle(
                                color: AppColors.info,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: subtleBorder, height: 1),
          const SizedBox(height: 6),

          // Fila Inferior: Switch de Acceso y Acciones [Clave], [Editar] y [Eliminar] ergonómicos (≥44dp)
          Row(
            children: [
              // Switch de Acceso con área táctil cómoda
              InkWell(
                onTap: () async {
                  final val = !personero.isActive;
                  if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                    setState(() {
                      _remotePersoneros![index] = _remotePersoneros![index].copyWith(isActive: val);
                    });
                  }
                  try {
                    final apiClient = ref.read(apiClientProvider);
                    await apiClient.patch('/personeros/${personero.id}/toggle-access');
                    await ref.read(personerosRepositoryProvider).togglePersoneroAccess(personero.id, dni: personero.dni);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: val ? successColor : warningColor,
                          content: Text(val ? 'Acceso habilitado para ${personero.firstName}.' : 'Acceso deshabilitado para ${personero.firstName}.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                      setState(() {
                        _remotePersoneros![index] = _remotePersoneros![index].copyWith(isActive: !val);
                      });
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: personero.isActive,
                        activeTrackColor: successColor.withValues(alpha: 0.5),
                        activeThumbColor: successColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) async {
                          if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                            setState(() {
                              _remotePersoneros![index] = _remotePersoneros![index].copyWith(isActive: val);
                            });
                          }
                          try {
                            final apiClient = ref.read(apiClientProvider);
                            await apiClient.patch('/personeros/${personero.id}/toggle-access');
                            await ref.read(personerosRepositoryProvider).togglePersoneroAccess(personero.id, dni: personero.dni);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: val ? successColor : warningColor,
                                  content: Text(val ? 'Acceso habilitado para ${personero.firstName}.' : 'Acceso deshabilitado para ${personero.firstName}.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                              setState(() {
                                _remotePersoneros![index] = _remotePersoneros![index].copyWith(isActive: !val);
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        personero.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: personero.isActive ? successColor : textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Botones de Acción con Touch Target ergonómico ≥44dp
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                tooltip: 'Editar Personero',
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () => PersoneroFormModal.show(context, personeroToEdit: personero),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: dangerColor),
                tooltip: 'Eliminar Personero',
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () {
                  DeletePersoneroDialog.show(
                    context,
                    personeroName: personero.fullName,
                    onConfirm: () async {
                      if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                        setState(() => _remotePersoneros!.removeAt(index));
                      }

                      await ref.read(personerosRepositoryProvider).deletePersonero(
                        personero.id,
                        dni: personero.dni,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.danger,
                            content: Text('Personero eliminado del sistema.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }

                      await ref.read(syncEngineProvider).syncPendingOperations();
                      await _refresh();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _onFilterChanged(bool? filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1;
      _remotePersoneros = null;
      _isLoading = true;
    });
    _loadInitialData();
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.accent,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? AppColors.accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
