/// Card especial que se muestra DENTRO del chat cuando Dr. Aurora
/// completa un diagnóstico por imagen.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/models/diagnosis_model.dart';
import 'diagnosis_detail_sheet.dart';

class DiagnosticsCard extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final String? imageUrl;
  final VoidCallback? onShowDetails;

  const DiagnosticsCard({
    super.key,
    required this.diagnosis,
    this.imageUrl,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del diagnóstico
            Row(
              children: [
                Icon(diagnosis.severityIcon, color: diagnosis.severityColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnóstico: ${diagnosis.problem}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confianza: ${(diagnosis.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barra de severidad visual
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Severidad', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(diagnosis.severityLabel, style: TextStyle(color: diagnosis.severityColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                // Barra de progreso de severidad
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: diagnosis.severityProgress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(diagnosis.severityColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descripción corta (máx 3 líneas)
            Text(
              diagnosis.description,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Thumbnail de la imagen (si disponible)
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 80, color: Colors.white10),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Botón "Ver Diagnóstico Completo"
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onShowDetails,
                icon: const Icon(Icons.science, size: 16),
                label: const Text('Ver Diagnóstico Completo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
