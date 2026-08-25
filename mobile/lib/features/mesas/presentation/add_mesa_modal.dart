import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';

class AddMesaModal extends ConsumerStatefulWidget {
  const AddMesaModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddMesaModal(),
    );
  }

  @override
  ConsumerState<AddMesaModal> createState() => _AddMesaModalState();
}

class _AddMesaModalState extends ConsumerState<AddMesaModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _districtController = TextEditingController();
  final _votersController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _votersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final repo = ref.read(mesasRepositoryProvider);

    try {
      final voters = int.tryParse(_votersController.text.trim()) ?? 300;
      await repo.createMesa(
        code: _codeController.text,
        locationName: _locationController.text,
        districtName: _districtController.text,
        registeredVoters: voters,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Mesa registrada exitosamente.'),
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Agregar Mesa de Votación',
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

              // Código de Mesa
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Número / Código de Mesa (Ej: 030394)',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.pin_outlined, color: textMuted),
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
                  if (val == null || val.trim().isEmpty) return 'El código de mesa es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Local de Votación
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Local de Votación',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.school_outlined, color: textMuted),
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
                    val == null || val.trim().isEmpty ? 'Ingrese el local de votación' : null,
              ),
              const SizedBox(height: 12),

              // Distrito
              TextFormField(
                controller: _districtController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Distrito',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.location_city_outlined, color: textMuted),
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
                    val == null || val.trim().isEmpty ? 'Ingrese el distrito' : null,
              ),
              const SizedBox(height: 12),

              // Electores Hábiles
              TextFormField(
                controller: _votersController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Electores Hábiles (Registrados)',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.group_outlined, color: textMuted),
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
                  if (val == null || val.trim().isEmpty) return 'Ingrese la cantidad de electores';
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) return 'Ingrese un número válido mayor a cero';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Asignación de Personero (Rol Personero)
              Consumer(
                builder: (context, ref, _) {
                  final personerosAsync = ref.watch(personerosStreamProvider);
                  return personerosAsync.when(
                    data: (personeros) {
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceOf(context),
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Personero Asignado (Opcional)',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: const Icon(Icons.person_pin_outlined, color: AppColors.accent),
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
                          DropdownMenuItem(
                            value: '',
                            child: Text(
                              '-- Ninguno (Sin Asignar) --',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textMuted),
                            ),
                          ),
                          ...personeros.map((p) => DropdownMenuItem(
                                value: p.dni,
                                child: Text(
                                  '${p.fullName} (DNI: ${p.dni})',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textPrimary),
                                ),
                              )),
                        ],
                        onChanged: (val) {
                          // Al seleccionar, se vinculará con este personero
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
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
                      : const Text(
                          'Guardar Mesa',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
