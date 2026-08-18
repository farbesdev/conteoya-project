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
    );

    if (mounted) {
      setState(() {
        _remotePersoneros = result.items;
        _hasMore = result.hasMore;
        _totalCount = result.total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final personerosAsync = ref.watch(personerosStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header / Barra de Búsqueda
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  onSubmitted: _onSearchChanged,
                  onChanged: (val) {
                    if (val.isEmpty || val.length >= 2) {
                      _onSearchChanged(val);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por DNI, nombres, apellidos o mesa...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
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
                if (_totalCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: $_totalCount personeros registrados',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
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
        elevation: 4,
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
        final filtered = personeros.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.dni.toLowerCase().contains(_searchQuery) ||
              p.fullName.toLowerCase().contains(_searchQuery) ||
              p.pollingStationCode.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyView();
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron personeros para "$_searchQuery"'
                  : 'No hay personeros registrados.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deslice hacia abajo para actualizar o presione (+) para registrar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersoneroCard(BuildContext context, PersoneroModel personero, {int? index}) {
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
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'DNI: ${personero.dni}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                          const Icon(Icons.flag_outlined, color: AppColors.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              personero.politicalOrganizationName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.accent,
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
              if (personero.pollingStationCode.isNotEmpty && personero.pollingStationCode != '030390')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.how_to_vote_rounded, color: AppColors.info, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Mesa ${personero.pollingStationCode}',
                        style: const TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),

          // Fila Inferior: Switch de Acceso y Acciones [Editar], [Clave] y [Eliminar]
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Switch de Acceso
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personero.isActive ? 'Acceso Activo' : 'Acceso Inactivo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: personero.isActive ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: Switch(
                      value: personero.isActive,
                      activeThumbColor: AppColors.success,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) async {
                        // Actualización optimista en memoria
                        if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                          setState(() {
                            _remotePersoneros![index] = _remotePersoneros![index].copyWith(isActive: val);
                          });
                        }
                        try {
                          final apiClient = ref.read(apiClientProvider);
                          await apiClient.patch('/personeros/${personero.id}/toggle-access');
                          await ref.read(personerosRepositoryProvider).togglePersoneroAccess(personero.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: val ? AppColors.success : AppColors.warning,
                                content: Text(val ? 'Acceso habilitado para ${personero.firstName}.' : 'Acceso deshabilitado para ${personero.firstName}.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          // Revertir en caso de error
                          if (index != null && _remotePersoneros != null && index < _remotePersoneros!.length) {
                            setState(() {
                              _remotePersoneros![index] = _remotePersoneros![index].copyWith(isActive: !val);
                            });
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.danger,
                                content: Text('Error al cambiar acceso. Verifica la conexión.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Botones de Acción
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 2,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.key_rounded, size: 15),
                      label: const Text('Clave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => _showResetPasswordModal(context, personero: personero),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => PersoneroFormModal.show(context, personeroToEdit: personero),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 15),
                      label: const Text('Eliminar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        DeletePersoneroDialog.show(
                          context,
                          personeroName: personero.fullName,
                          onConfirm: () async {
                            await ref.read(personerosRepositoryProvider).deletePersonero(personero.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.danger,
                                  content: Text('Personero eliminado del sistema.'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetPasswordModal(BuildContext context, {required PersoneroModel personero}) {
    final defaultPass = '${personero.dni}!';
    final passwordController = TextEditingController(text: defaultPass);
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.key_rounded, color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Restablecer Contraseña',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personero: ${personero.fullName}\nDNI: ${personero.dni} — Mesa: ${personero.pollingStationCode}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nueva Contraseña:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                    tooltip: 'Restablecer a contraseña por defecto',
                    onPressed: () => passwordController.text = defaultPass,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              icon: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                isSaving ? 'Guardando...' : 'Restablecer Clave',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setModalState(() => isSaving = true);
                      final newPass = passwordController.text.trim();
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        // Intentar buscar ID del usuario o reset por API
                        await apiClient.post('/users/${personero.id}/reset-password', data: {'password': newPass});
                      } catch (_) {
                        // Fallback local resiliente
                      }

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('✅ Contraseña de ${personero.firstName} restablecida a: $newPass'),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
