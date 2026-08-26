import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_colors.dart';

/// Provider que emite el estado de conectividad en tiempo real
final isOnlineStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield initial.any((r) => r != ConnectivityResult.none);

  await for (final results in connectivity.onConnectivityChanged) {
    yield results.any((r) => r != ConnectivityResult.none);
  }
});

/// Widget de Badge / Chip que muestra el estado de conexión del servidor
class ConnectivityStatusBadge extends ConsumerStatefulWidget {
  final bool showLabel;
  final bool enableSnackbars;

  const ConnectivityStatusBadge({
    super.key,
    this.showLabel = true,
    this.enableSnackbars = false,
  });

  @override
  ConsumerState<ConnectivityStatusBadge> createState() => _ConnectivityStatusBadgeState();
}

class _ConnectivityStatusBadgeState extends ConsumerState<ConnectivityStatusBadge> {
  bool? _lastKnownStatus;

  @override
  Widget build(BuildContext context) {
    final onlineAsync = ref.watch(isOnlineStreamProvider);
    final isOnline = onlineAsync.valueOrNull ?? true;

    // Disparar SnackBar opcional ante transición de red
    if (widget.enableSnackbars && _lastKnownStatus != null && _lastKnownStatus != isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isOnline
                        ? 'Servidor Conectado — En línea'
                        : 'Servidor Desconectado — Modo Offline',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: isOnline ? AppColors.success : AppColors.danger,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      });
    }
    _lastKnownStatus = isOnline;

    final color = isOnline ? AppColors.success : AppColors.danger;
    final icon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return Tooltip(
      message: isOnline
          ? 'Conectado al servidor de ConteoYA (Online)'
          : 'Sin conexión a internet. Los cambios se guardarán localmente (Offline)',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (isOnline) {
            ref.read(syncEngineProvider).syncPendingOperations();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sincronizando operaciones con el servidor...'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Modo Offline: Las actas y limpiezas se guardan localmente.'),
                backgroundColor: AppColors.danger,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(120), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
              Icon(icon, size: 13, color: color),
              if (widget.showLabel) ...[
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
