import 'package:flutter/material.dart';
import '../gengar_colors.dart';

/// Pill-shaped translucent search field used across Plataformas/Biblioteca.
class GengarSearchField extends StatelessWidget {
  const GengarSearchField({
    super.key,
    this.controller,
    this.hintText = 'Pesquisar…',
    this.onChanged,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: GengarColors.textFaint),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isCollapsed: true,
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: GengarColors.textFaint),
              ),
            ),
          ),
          ?suffixIcon,
        ],
      ),
    );
  }
}
