/// Dropdown con estética glass y overlay custom.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/config/app_theme.dart';

/// Modelo para un item del dropdown.
class DropdownItem {
  final String value;
  final String label;
  final IconData? icon;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class GlassDropdown extends StatelessWidget {
  final List<DropdownItem> items;
  final String? selectedValue;
  final String hint;
  final ValueChanged<String> onChanged;

  const GlassDropdown({
    super.key,
    required this.items,
    this.selectedValue,
    required this.hint,
    required this.onChanged,
  });

  String? get _selectedLabel {
    if (selectedValue == null) return null;
    final item = items.where((i) => i.value == selectedValue);
    return item.isNotEmpty ? item.first.label : null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOverlay(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedValue != null
                ? AppTheme.primary.withValues(alpha: 0.3)
                : AppTheme.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedLabel ?? hint,
                style: TextStyle(
                  color: selectedValue != null
                      ? AppTheme.textPrimary
                      : AppTheme.textTertiary,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Título
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    hint,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(color: AppTheme.glassBorder, height: 1),
                // Items
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isActive = item.value == selectedValue;
                      return _DropdownOption(
                        item: item,
                        isSelected: isActive,
                        onTap: () {
                          onChanged(item.value);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropdownOption extends StatelessWidget {
  final DropdownItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownOption({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
