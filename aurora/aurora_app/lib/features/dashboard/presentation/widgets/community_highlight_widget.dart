
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';

class CommunityHighlightWidget extends StatelessWidget {
  const CommunityHighlightWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/social'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
               Text("Trending in Community 🔥", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: Colors.white24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Check out the latest posts", style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 4),
                    Text("See what other growers are doing", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
