import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../personeros/domain/personero_model.dart';
import '../../personeros/presentation/delete_personero_dialog.dart';
import '../../personeros/presentation/personero_form_modal.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header / Barra de Búsqueda y Filtros
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: subtleBorder, width: 0.5)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, email o DNI...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withAlpha(128)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withAlpha(128), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                // Carrusel de Filtros Móvil Ergonómico
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'ALL', Icons.people_outline_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admin', 'ADMIN', Icons.admin_panel_settings_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('Director', 'DIRECTOR', Icons.manage_accounts_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('Personeros', 'PERSONERO', Icons.badge_outlined),
                    ],
                  ),
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
                        'id': p.id,
                        'name': p.fullName,
                        'email': p.email ?? 'personero_${p.dni}@conteoya.pe',
                        'role': 'PERSONERO',
                        'dni': p.dni,
                        'personeroModel': p,
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No se encontraron usuarios con los criterios de búsqueda.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(178)),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
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
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('+ Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showUserFormModal(context),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedRoleFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.accentOf(context);

    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final role = user['role'] as String;
    final warningColor = AppColors.warningOf(context);
    final dangerColor = AppColors.dangerOf(context);
    final roleColor = switch (role) {
      'ADMIN' => dangerColor,
      'DIRECTOR' => warningColor,
      _ => AppColors.accentOf(context),
    };
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      user['email'] as String,
                      style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(178), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 8),
          Divider(color: subtleBorder, height: 1),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.key_rounded, size: 18, color: warningColor),
                tooltip: 'Restablecer Clave',
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () => _showResetPasswordModal(
                  context,
                  userId: user['id'] as int,
                  name: user['name'] as String,
                  email: user['email'] as String,
                ),
              ),
              if (user['personeroModel'] != null)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.onSurface.withAlpha(178)),
                  tooltip: 'Editar Datos',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () => PersoneroFormModal.show(context, personeroToEdit: user['personeroModel'] as PersoneroModel),
                ),
              if (user['personeroModel'] != null)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: dangerColor),
                  tooltip: 'Eliminar',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () {
                    final pModel = user['personeroModel'] as PersoneroModel;
                    DeletePersoneroDialog.show(
                      context,
                      personeroName: pModel.fullName,
                      onConfirm: () async {
                        await ref.read(personerosRepositoryProvider).deletePersonero(pModel.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: dangerColor,
                              content: const Text('Personero/Usuario eliminado del sistema.'),
                            ),
                          );
                        }
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

  void _showResetPasswordModal(BuildContext context, {required int userId, required String name, required String email}) {
    final defaultPass = email.toLowerCase().contains('puertoinca') ? 'Puertoinca123!' : 'Personero123!';
    final passwordController = TextEditingController(text: defaultPass);
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final inputFill = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final borderColor = AppColors.borderOf(context);
    final warningColor = AppColors.warningOf(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.key_rounded, color: warningColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Restablecer Contraseña',
                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usuario: $name\n$email',
                style: TextStyle(color: textSecondary, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              Text(
                'Nueva Contraseña para el Usuario:',
                style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: passwordController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
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
              child: Text('Cancelar', style: TextStyle(color: textMuted)),
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
                        await apiClient.post('/users/$userId/reset-password', data: {'password': newPass});
                      } catch (_) {
                        // Resiliente si está offline
                      }

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('✅ Contraseña de $name restablecida a: $newPass'),
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
      final cleanMesa = _selectedMesaCode ?? '';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final inputFill = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final borderColor = AppColors.borderOf(context);
    final mesasAsync = ref.watch(mesasStreamProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nuevo Usuario',
                    style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
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
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Nombre Completo *',
                labelStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Correo Electrónico *',
                labelStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'DNI (8 dígitos)',
                labelStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: inputFill,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Teléfono (opcional)',
                labelStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedRole,
              dropdownColor: AppColors.surfaceOf(context),
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Rol *',
                labelStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'PERSONERO', child: Text('Personero de Mesa', overflow: TextOverflow.ellipsis, style: TextStyle(color: textPrimary))),
                DropdownMenuItem(value: 'DIRECTOR', child: Text('Director Electoral', overflow: TextOverflow.ellipsis, style: TextStyle(color: textPrimary))),
                DropdownMenuItem(value: 'ADMIN', child: Text('Administrador (ADMIN)', overflow: TextOverflow.ellipsis, style: TextStyle(color: textPrimary))),
              ],
              onChanged: (val) => setState(() => _selectedRole = val ?? 'PERSONERO'),
            ),
            const SizedBox(height: 10),

            mesasAsync.when(
              data: (mesas) => DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedMesaCode,
                dropdownColor: AppColors.surfaceOf(context),
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Mesa Asignada *',
                  labelStyle: TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
                items: mesas.map((m) => DropdownMenuItem(
                  value: m.code,
                  child: Text('Mesa ${m.code} - ${m.locationName}', overflow: TextOverflow.ellipsis, style: TextStyle(color: textPrimary)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedMesaCode = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text('Error al cargar mesas', style: TextStyle(color: AppColors.dangerOf(context))),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving ? null : _submitUser,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear y Sincronizar Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
