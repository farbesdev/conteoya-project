import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PartyLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final String? shortName;
  final int? partyId;
  final double size;

  const PartyLogoWidget({
    super.key,
    required this.logoUrl,
    required this.name,
    this.shortName,
    this.partyId,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final initials = (shortName != null && shortName!.isNotEmpty)
        ? (shortName!.length > 4 ? shortName!.substring(0, 4) : shortName!)
        : name
            .split(' ')
            .where((w) => w.isNotEmpty && w.length > 2)
            .map((w) => w[0])
            .take(3)
            .join();

    String? resolvedUrl = (logoUrl != null && logoUrl!.trim().startsWith('http'))
        ? logoUrl!.trim()
        : (partyId != null
            ? 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/$partyId.png'
            : null);

    // En emulador Android, 127.0.0.1 y localhost deben mapearse a 10.0.2.2 (host)
    if (resolvedUrl != null) {
      resolvedUrl = resolvedUrl
          .replaceAll('://127.0.0.1', '://10.0.2.2')
          .replaceAll('://localhost', '://10.0.2.2');
    }

    final hasValidUrl = resolvedUrl != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasValidUrl
          ? Image.network(
              resolvedUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildFallback(initials),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            )
          : _buildFallback(initials),
    );
  }

  Widget _buildFallback(String initials) {
    return Container(
      color: AppColors.accent.withValues(alpha: 0.15),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(2),
      child: Text(
        initials.isEmpty ? 'OP' : initials.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.28,
        ),
      ),
    );
  }
}
