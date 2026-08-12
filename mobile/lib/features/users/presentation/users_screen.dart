import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personerosAsync = ref.watch(personerosStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header / Barra de Búsqueda y Filtros
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, email o DNI...',
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
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFilterChip('TODOS', 'ALL'),
                    const SizedBox(width: 6),
                    _buildFilterChip('ADMIN', 'ADMIN'),
                    const SizedBox(width: 6),
                    _buildFilterChip('DIRECTOR', 'DIRECTOR'),
                    const SizedBox(width: 6),
                    _buildFilterChip('PERSONEROS', 'PERSONERO'),
                  ],
                ),
              ],
            ),
          ),

          // Listado de Usuarios (Integrado con Personeros)
          Expanded(
            child: personerosAsync.when(
              data: (personeros) {
                // Usuarios demo integrados
                final allUsers = [
                  {
                    'id': 1,
                    'name': 'Administrador ConteoYA',
                    'email': 'admin@conteoya.pe',
                    'role': 'ADMIN',
                    'isActive': true,
                  },
                  {
                    'id': 2,
                    'name': 'Director Electoral Demo',
                    'email': 'director@conteoya.pe',
                    'role': 'DIRECTOR',
                    'isActive': true,
                  },
                  ...personeros.map((p) => {
                        'id': p.id + 10,
                        'name': p.fullName,
                        'email': p.email ?? 'personero@conteoya.pe',
                        'role': 'PERSONERO',
                        'dni': p.dni,
                        'mesa': p.pollingStationCode,
                        'isActive': true,
                      }),
                ];

                final filtered = allUsers.where((u) {
                  final role = u['role'] as String;
                  if (_selectedRoleFilter != 'ALL' && role != _selectedRoleFilter) return false;
                  if (_searchQuery.isEmpty) return true;

                  final name = (u['name'] as String).toLowerCase();
                  final email = (u['email'] as String).toLowerCase();
                  final dni = (u['dni'] as String?)?.toLowerCase() ?? '';

                  return name.contains(_searchQuery) || email.contains(_searchQuery) || dni.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No se encontraron usuarios con los criterios de búsqueda.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    return _buildUserCard(context, u);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_user',
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('+ Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showUserFormModal(context),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRoleFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final role = user['role'] as String;
    final roleColor = switch (role) {
      'ADMIN' => AppColors.danger,
      'DIRECTOR' => AppColors.warning,
      _ => AppColors.accent,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  role == 'ADMIN'
                      ? Icons.admin_panel_settings_rounded
                      : role == 'DIRECTOR'
                          ? Icons.manage_accounts_rounded
                          : Icons.person_rounded,
                  color: roleColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] as String,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      user['email'] as String,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  role,
                  style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (user['mesa'] != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.how_to_vote_rounded, color: AppColors.info, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Mesa Asignada: ${user['mesa']}',
                  style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showUserFormModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const UserFormModal(),
    );
  }
}

class UserFormModal extends ConsumerStatefulWidget {
  const UserFormModal({super.key});

  @override
  ConsumerState<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends ConsumerState<UserFormModal> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'PERSONERO';
  String? _selectedMesaCode;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final dni = _dniController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      setState(() => _errorMessage = 'Nombre y correo son obligatorios.');
      return;
    }

    if (_selectedRole == 'PERSONERO') {
      if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
        setState(() => _errorMessage = 'El DNI debe contener 8 dígitos numéricos.');
        return;
      }
      if (_selectedMesaCode == null || _selectedMesaCode!.isEmpty) {
        setState(() => _errorMessage = 'Debe seleccionar una mesa asignada.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ' ';
      final cleanDni = dni.isNotEmpty ? dni : 'DNI${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final cleanMesa = _selectedMesaCode ?? '030390';

      final repo = ref.read(personerosRepositoryProvider);
      await repo.createPersonero(
        dni: cleanDni,
        firstName: firstName,
        lastName: lastName,
        pollingStationCode: cleanMesa,
        phoneNumber: phone.isNotEmpty ? phone : null,
        email: email,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario guardado y encolado para sincronización.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final mesasAsync = ref.watch(mesasStreamProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo Usuario', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
              const SizedBox(height: 10),
            ],

            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Nombre Completo *', filled: true, fillColor: AppColors.background),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Correo Electrónico *', filled: true, fillColor: AppColors.background),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'DNI (8 dígitos)', filled: true, fillColor: AppColors.background, counterText: ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)', filled: true, fillColor: AppColors.background),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Rol *', filled: true, fillColor: AppColors.background),
              items: const [
                DropdownMenuItem(value: 'PERSONERO', child: Text('Personero de Mesa')),
                DropdownMenuItem(value: 'DIRECTOR', child: Text('Director Electoral')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Administrador (ADMIN)')),
              ],
              onChanged: (val) => setState(() => _selectedRole = val ?? 'PERSONERO'),
            ),
            const SizedBox(height: 10),

            mesasAsync.when(
              data: (mesas) => DropdownButtonFormField<String>(
                initialValue: _selectedMesaCode,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Mesa Asignada *', filled: true, fillColor: AppColors.background),
                items: mesas.map((m) => DropdownMenuItem(
                  value: m.code,
                  child: Text('Mesa ${m.code} - ${m.locationName}'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedMesaCode = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error al cargar mesas'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _isSaving ? null : _submitUser,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear y Sincronizar Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
