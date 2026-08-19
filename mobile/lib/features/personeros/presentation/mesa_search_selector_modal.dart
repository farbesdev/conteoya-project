import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../mesas/domain/mesa_model.dart';

class MesaSearchSelectorModal extends ConsumerStatefulWidget {
  final List<String> initialSelectedCodes;

  const MesaSearchSelectorModal({
    super.key,
    required this.initialSelectedCodes,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> initialSelectedCodes,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MesaSearchSelectorModal(
        initialSelectedCodes: initialSelectedCodes,
      ),
    );
  }

  @override
  ConsumerState<MesaSearchSelectorModal> createState() => _MesaSearchSelectorModalState();
}

class _MesaSearchSelectorModalState extends ConsumerState<MesaSearchSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  late Set<String> _selectedCodes;
  List<MesaModel> _searchResults = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCodes = Set.from(widget.initialSelectedCodes);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch('', page: 1);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150) {
      if (!_isLoading && _hasMore) {
        _performSearch(_currentQuery, page: _currentPage + 1, isLoadMore: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query, page: 1);
    });
  }

  Future<void> _performSearch(String query, {int page = 1, bool isLoadMore = false}) async {
    final cleanQuery = query.trim();
    setState(() {
      _isLoading = true;
      _currentQuery = cleanQuery;
      if (!isLoadMore) {
        _currentPage = 1;
      }
    });

    final mesasRepo = ref.read(mesasRepositoryProvider);
    final result = await mesasRepo.fetchRemotePollingStations(
      search: cleanQuery,
      page: page,
      perPage: 15,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentPage = page;
        _hasMore = result.hasMore;

        if (isLoadMore) {
          final existingCodes = _searchResults.map((m) => m.code).toSet();
          final newUnique = result.items.where((m) => !existingCodes.contains(m.code)).toList();
          _searchResults = [..._searchResults, ...newUnique];
        } else {
          _searchResults = result.items;
        }
      });
    }
  }

  void _toggleMesa(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        _selectedCodes.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buscar y Asignar Mesas',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Selecciona una o varias mesas para el personero',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (val) {
                _debounceTimer?.cancel();
                FocusScope.of(context).unfocus();
                _performSearch(val, page: 1);
              },
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por número de mesa, distrito u ODPE...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('', page: 1);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
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

          // Chips de Mesas Seleccionadas Rápidas
          if (_selectedCodes.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Seleccionadas (${_selectedCodes.length}): ',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ..._selectedCodes.map((code) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          side: const BorderSide(color: AppColors.accent, width: 0.8),
                          label: Text(
                            'Mesa $code',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.accent),
                          onDeleted: () => _toggleMesa(code),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.border),

          // Lista de Resultados
          Expanded(
            child: _isLoading && _searchResults.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              _currentQuery.isNotEmpty
                                  ? 'No se encontraron mesas para "$_currentQuery"'
                                  : 'No hay mesas disponibles',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _searchResults.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final mesa = _searchResults[index];
                          final isSelected = _selectedCodes.contains(mesa.code);

                          return InkWell(
                            onTap: () => _toggleMesa(mesa.code),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.12)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.border.withValues(alpha: 0.6),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Checkbox circular
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.accent : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.accent : AppColors.textMuted,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Datos de la mesa
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Mesa ${mesa.code}',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppColors.accent
                                                    : AppColors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.info.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${mesa.registeredVoters} electores',
                                                style: const TextStyle(
                                                  color: AppColors.info,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          mesa.locationName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${mesa.districtName} — ${mesa.provinceName}, ${mesa.departmentName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Bar de Confirmación
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedCodes.length} ${_selectedCodes.length == 1 ? 'mesa seleccionada' : 'mesas seleccionadas'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'El personero podrá capturar actas de estas mesas',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _selectedCodes.toList());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
