/// Bottom Sheet modal con el diagnóstico expandido completo.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/aurora_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/models/diagnosis_model.dart';

class DiagnosisDetailSheet extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final String? imageUrl;

  const DiagnosisDetailSheet({
    super.key,
    required this.diagnosis,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              
              // Título
              Row(
                children: [
                  const Icon(Icons.biotech, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Diagnóstico Completo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Imagen del usuario (si existe)
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Problema detectado + severidad
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Problema Detectado', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(diagnosis.problem, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Severidad + confianza en Row
                      Row(
                        children: [
                          _SeverityChip(diagnosis.severityLabel, diagnosis.severityColor),
                          const SizedBox(width: 8),
                          _ConfidenceChip('${(diagnosis.confidence * 100).toStringAsFixed(0)}% confianza'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Barra de severidad grande
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: diagnosis.severityProgress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(diagnosis.severityColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Descripción
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description, color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Descripción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(diagnosis.description, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Causas posibles
              if (diagnosis.causes.isNotEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.search, color: Color(0xFFFFA726), size: 18),
                            SizedBox(width: 8),
                            Text('Causas Posibles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...diagnosis.causes.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${entry.key + 1}. ', style: const TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.w600)),
                              Expanded(child: Text(entry.value, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Soluciones paso a paso
              if (diagnosis.solutions.isNotEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: AppTheme.primary, size: 18),
                            SizedBox(width: 8),
                            Text('Soluciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...diagnosis.solutions.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(child: Text('${entry.key + 1}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(entry.value, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Tiempo de recuperación
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Color(0xFF4FC3F7), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tiempo Estimado de Recuperación', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          Text(diagnosis.estimatedRecovery, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón de acción
              AuroraButton(
                text: 'Preguntarle más a Dr. Aurora',
                onPressed: () {
                  Navigator.pop(context);
                  // El chat ya está abierto, el usuario puede seguir escribiendo
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  final String label;

  const _ConfidenceChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
