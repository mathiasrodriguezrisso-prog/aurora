
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';

class AuroraTipCard extends StatelessWidget {
  const AuroraTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: () => context.push('/chat'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Dr. Aurora", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Tap to chat about your grow.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
