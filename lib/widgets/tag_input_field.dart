import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A text field that lets users type items and
/// displays them as removable chips above the input.
/// Used for allergies, medications, and conditions.
class TagInputField extends StatefulWidget {
  final String label;
  final List<String> initialTags;
  final String hint;
  final Color? color;
  final Function(List<String>) onChanged;

  const TagInputField({
    super.key,
    required this.label,
    required this.initialTags,
    required this.onChanged,
    this.hint = 'Type and press Enter or ➕ to add',
    this.color,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _ctrl = TextEditingController();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (_tags.contains(value)) {
      _ctrl.clear();
      return;
    }
    setState(() => _tags.add(value));
    widget.onChanged(List.from(_tags));
    _ctrl.clear();
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged(List.from(_tags));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Chips
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: _tags
                .map((tag) => Chip(
              label: Text(
                tag,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              backgroundColor: color.withValues(alpha:0.1),
              deleteIconColor: color,
              side: BorderSide(color: color.withValues(alpha:0.3)),
              onDeleted: () => _remove(tag),
              materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Input Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.done,
                onSubmitted: _add,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _add(_ctrl.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }
}