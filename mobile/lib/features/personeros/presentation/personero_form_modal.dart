import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/personero_model.dart';
import 'mesa_search_selector_modal.dart';

class PersoneroFormModal extends ConsumerStatefulWidget {
  final PersoneroModel? personeroToEdit;

  const PersoneroFormModal({super.key, this.personeroToEdit});

  static Future<void> show(BuildContext context, {PersoneroModel? personeroToEdit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PersoneroFormModal(personeroToEdit: personeroToEdit),
    );
  }

  @override
  ConsumerState<PersoneroFormModal> createState() => _PersoneroFormModalState();
}

class _PersoneroFormModalState extends ConsumerState<PersoneroFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late final Set<String> _selectedMesaCodes;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.personeroToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.personeroToEdit;
    _dniController = TextEditingController(text: p?.dni ?? '');
    _firstNameController = TextEditingController(text: p?.firstName ?? '');
    _lastNameController = TextEditingController(text: p?.lastName ?? '');
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');

    _selectedMesaCodes = {};
    if (p != null) {
      if (p.pollingStationCodes.isNotEmpty) {
        _selectedMesaCodes.addAll(p.pollingStationCodes);
      } else if (p.pollingStationCode.isNotEmpty) {
        _selectedMesaCodes.add(p.pollingStationCode);
      }
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _openMesaSelector() async {
    final result = await MesaSearchSelectorModal.show(
      context,
      initialSelectedCodes: _selectedMesaCodes.toList(),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMesaCodes.clear();
        _selectedMesaCodes.addAll(result);
        if (_selectedMesaCodes.isNotEmpty) {
          _errorMessage = null;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedMesaCodes.isEmpty) {
      setState(() {
        _errorMessage = 'Debe asignar al menos una mesa de votación al personero.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final repo = ref.read(personerosRepositoryProvider);

    try {
      if (_isEditing) {
        await repo.updatePersonero(
          id: widget.personeroToEdit!.id,
          dni: _dniController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          pollingStationCodes: _selectedMesaCodes.toList(),
          phoneNumber: _phoneController.text,
          email: _emailController.text,
        );
      } else {
        await repo.createPersonero(
          dni: _dniController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          pollingStationCodes: _selectedMesaCodes.toList(),
          phoneNumber: _phoneController.text,
          email: _emailController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              _isEditing ? 'Personero actualizado exitosamente' : 'Personero registrado exitosamente',
            ),
          ),
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
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

              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Personero' : 'Agregar Personero',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo DNI
              TextFormField(
                controller: _dniController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'DNI (8 dígitos)',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.badge_outlined, color: textMuted),
                  counterStyle: TextStyle(color: textMuted),
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
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'El DNI es obligatorio';
                  if (!RegExp(r'^\d{8}$').hasMatch(val.trim())) {
                    return 'Ingrese exactamente 8 dígitos numéricos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Nombres y Apellidos
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Nombres',
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
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Ingrese nombres' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
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
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Ingrese apellidos' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── SECCIÓN MESAS DE VOTACIÓN ASIGNADAS (Múltiples) ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedMesaCodes.isEmpty && _errorMessage != null
                        ? AppColors.danger
                        : borderColor,
                    width: _selectedMesaCodes.isEmpty && _errorMessage != null ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.how_to_vote_outlined, color: AppColors.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Mesas Asignadas (${_selectedMesaCodes.length}) *',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _openMesaSelector,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.search_rounded, size: 16, color: AppColors.accent),
                          label: Text(
                            _selectedMesaCodes.isEmpty ? 'Buscar Mesas' : 'Editar Mesas',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_selectedMesaCodes.isEmpty)
                      InkWell(
                        onTap: _openMesaSelector,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_location_alt_outlined, color: textMuted, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                'Toque aquí para buscar y asignar mesas al personero',
                                style: TextStyle(color: textSecondary, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMesaCodes.map((code) {
                          return Chip(
                            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                            side: const BorderSide(color: AppColors.accent, width: 0.8),
                            avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.accent),
                            label: Text(
                              'Mesa $code',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.accent),
                            onDeleted: () {
                              setState(() {
                                _selectedMesaCodes.remove(code);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Teléfono (Opcional)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Teléfono / Celular (Opcional)',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.phone_outlined, color: textMuted),
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
              const SizedBox(height: 24),

              // Botón Guardar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isEditing ? 'Actualizar Personero' : 'Guardar Personero',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
