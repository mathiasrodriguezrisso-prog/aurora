/// Barra de búsqueda glass con filtrado y autocompletado.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/app_theme.dart';

class GlassSearchBar extends StatefulWidget {
  final String hint;
  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onChanged;
  final Duration debounceDuration;

  const GlassSearchBar({
    super.key,
    required this.hint,
    required this.suggestions,
    required this.onSelected,
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<String> _filtered = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    widget.onChanged?.call(text);

    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      setState(() {
        if (text.trim().isEmpty) {
          _filtered = [];
          _showSuggestions = false;
        } else {
          final query = text.toLowerCase();
          _filtered = widget.suggestions
              .where((s) => s.toLowerCase().contains(query))
              .toList();
          _showSuggestions = _filtered.isNotEmpty;
        }
      });
    });
  }

  void _selectSuggestion(String value) {
    _controller.text = value;
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
    widget.onSelected(value);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _filtered = [];
      _showSuggestions = false;
    });
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo de búsqueda
        Container(
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : AppTheme.glassBorder,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                      onPressed: _clear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Sugerencias
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final item = _filtered[index];
                return InkWell(
                  onTap: () => _selectSuggestion(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ] else if (_controller.text.isNotEmpty && _filtered.isEmpty && _focusNode.hasFocus) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: const Text(
              'No se encontraron resultados',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
