
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/aurora_chip.dart';
import '../providers/chat_providers.dart';

class ActionChips extends ConsumerWidget {
  const ActionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      "Diagnose Issue",
      "Nutrient Schedule",
      "Environment Check",
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Center(
            child: AuroraChip(
              label: actions[index],
              isSelected: false,
              onTap: () {
                ref.read(chatMessagesProvider.notifier).sendMessage(actions[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
