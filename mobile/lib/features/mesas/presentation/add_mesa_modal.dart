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
  final _locationController = TextEditingController(text: 'I.E. NUESTRA SEÑORA DE GUADALUPE');
  final _districtController = TextEditingController(text: 'LIMA - CERCADO');
  final _votersController = TextEditingController(text: '300');

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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                    color: AppColors.border,
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
                  const Text(
                    'Agregar Mesa de Votación',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
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
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Número / Código de Mesa (Ej: 030394)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
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
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Local de Votación',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.school_outlined, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
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
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Distrito',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
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
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Electores Hábiles (Registrados)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.group_outlined, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
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
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Personero Asignado (Opcional)',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.person_pin_outlined, color: AppColors.accent),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('-- Ninguno (Sin Asignar) --', style: TextStyle(color: AppColors.textMuted)),
                          ),
                          ...personeros.map((p) => DropdownMenuItem(
                                value: p.dni,
                                child: Text('${p.fullName} (DNI: ${p.dni})'),
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
